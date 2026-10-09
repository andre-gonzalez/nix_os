# Disko disk layout: EFI + LUKS2 + btrfs with subvolumes and an in-container swapfile.
# Encrypted counterpart to hardware/disko-btrfs.nix, which stays as-is for hosts
# that do not want full-disk encryption.
#
# WARNING: applying this ERASES the entire target disk (default /dev/sda).
# Override the device per-host with:  disko.devices.disk.main.device = "/dev/nvme0n1";
#
# Layout:
#   ESP   512M vfat  -> /boot/efi     (GRUB EFI binary only)
#   luks  100%       -> btrfs
#           @        -> /             compress=zstd,noatime
#           @home    -> /home         compress=zstd,noatime
#           @nix     -> /nix          compress=zstd,noatime
#           @swap    -> /swap         8G swapfile, NOCOW + no compression
#
# Two deliberate differences from disko-btrfs.nix:
#
#   * There is NO swap partition. disko-btrfs.nix puts a *plaintext* swap
#     partition outside the encrypted container with resumeDevice = true; under
#     LUKS that leaks RAM contents to disk in the clear. Here swap is a file
#     *inside* the encrypted btrfs, and hibernation is not configured at all.
#   * /boot lives inside LUKS (on the @ subvolume), so kernels and initrds are
#     encrypted too. That requires GRUB to open the container itself — see
#     enableCryptodisk in the host file and the pbkdf2 note below.
{ config, lib, ... }:
let
  cfg = config.local.diskoLuks;
in
{
  options.local.diskoLuks = {
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/tmp/luks.key";
      description = ''
        Path *on the installer* to a file holding the LUKS passphrase, read by
        disko at format time. Only ever consulted while formatting — it has no
        effect on an installed system, and the file is never copied to the
        target.

        null (the default) makes cryptsetup prompt interactively, which is what
        you want for a local install from the ISO. A non-interactive install
        (nixos-anywhere over ssh) has no tty for that prompt, so it must set
        this and ship the file with `--disk-encryption-keys`.
      '';
    };

    useInitrdKeyFile = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Add /tmp/crypto_keyfile.bin as a second LUKS key slot, so the initrd can
        unlock without a second passphrase prompt (GRUB asks once and hands off).
        Safe only because /boot — and therefore the initrd carrying the embedded
        key — is itself inside the container.

        Requires the keyfile to exist BEFORE disko runs:
          dd if=/dev/urandom of=/tmp/crypto_keyfile.bin bs=512 count=8
          chmod 0600 /tmp/crypto_keyfile.bin
        and to be copied to /mnt/boot/crypto_keyfile.bin (0600) after mount,
        before nixos-install. See hosts/t14/INSTALL.md.

        Set false to accept two passphrase prompts instead (cosmetic only). The
        matching boot.initrd.secrets / boot.initrd.luks keyFile lines live in
        this module too, gated on this same option, so the extra key slot and
        its consumer can never drift apart.
      '';
    };
  };

  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = lib.mkDefault "/dev/sda";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  # Mounted at /boot/efi, not /boot: /boot is on the encrypted
                  # btrfs so only the GRUB EFI binary sits in the clear.
                  mountpoint = "/boot/efi";
                  mountOptions = [ "umask=0077" ];
                };
              };
              luks = {
                priority = 2;
                name = "luks";
                size = "100%";
                content = {
                  type = "luks";
                  name = "cryptroot";
                  # GRUB 2.12 in this nixpkgs pin carries no argon2 patch, so a
                  # default (argon2id) LUKS2 header is unreadable to it and the
                  # machine will not boot. Force the PBKDF back to pbkdf2.
                  extraFormatArgs = [ "--pbkdf" "pbkdf2" ];

                  # null => interactive prompt (local ISO install).
                  passwordFile = cfg.passwordFile;

                  # Second key slot for the initrd; see the option description.
                  additionalKeyFiles =
                    lib.optionals cfg.useInitrdKeyFile [ "/tmp/crypto_keyfile.bin" ];

                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ]; # force overwrite any existing filesystem
                    subvolumes = {
                      # Snapshotted by snapper (config "root"). Carries /boot.
                      "@" = {
                        mountpoint = "/";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      # Snapshotted by snapper (config "home")
                      "@home" = {
                        mountpoint = "/home";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      # Nix store — compressed, no snapshots needed
                      "@nix" = {
                        mountpoint = "/nix";
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      # Swapfile host. disko runs `btrfs filesystem mkswapfile`,
                      # which sets NOCOW itself; the subvolume must not be
                      # compressed or snapshotted.
                      "@swap" = {
                        mountpoint = "/swap";
                        mountOptions = [ "noatime" ];
                        swap.swapfile.size = "8G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    # /boot is inside the container, so GRUB has to open it itself.
    boot.loader.grub.enableCryptodisk = true;

    # Single passphrase prompt: GRUB asks once, then hands off to an initrd that
    # carries a keyfile for the second LUKS key slot. Only safe because /boot —
    # and so the initrd with the embedded key — is itself encrypted.
    # useInitrdKeyFile = false (hosts/t14/remote-install.nix) exists because
    # boot.initrd.secrets is resolved *during* nixos-install, before
    # nixos-anywhere copies --extra-files into /mnt, so an unattended install
    # cannot provide /boot/crypto_keyfile.bin in time.
    boot.initrd.secrets."/crypto_keyfile.bin" =
      lib.mkIf cfg.useInitrdKeyFile "/boot/crypto_keyfile.bin";
    boot.initrd.luks.devices.cryptroot.keyFile =
      lib.mkIf cfg.useInitrdKeyFile "/crypto_keyfile.bin";

    # zram is preferred over the disk swapfile (higher priority number wins).
    # 25% of RAM (≈ 6.8 G on the 27 GiB t14), scaled up from the 4 G used on
    # Arch. The 8 G file below it is the overflow tier only.
    zramSwap = {
      enable = true;
      memoryPercent = 25;
      priority = 100;
    };
  };
}
