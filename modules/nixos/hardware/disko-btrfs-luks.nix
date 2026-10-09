# Disko disk layout: EFI + LUKS2 + btrfs with subvolumes and an in-container swapfile.
# Encrypted counterpart to hardware/disko-btrfs.nix, which stays as-is for hosts
# that do not want full-disk encryption.
#
# WARNING: applying this ERASES the entire target disk (default /dev/sda).
# Override the device per-host with:  disko.devices.disk.main.device = "/dev/nvme0n1";
#
# Layout:
#   ESP   1G   vfat  -> /boot         (GRUB, kernels, initrds — unencrypted)
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
#
# /boot is deliberately OUTSIDE the container, as it was on Arch. An encrypted
# /boot makes GRUB unlock LUKS, and GRUB reads the passphrase with a US keymap
# before it can load any other (the unlock happens in its core image, ahead of
# grub.cfg) — unusable with a Dvorak-typed passphrase. Here the initrd unlocks
# instead, after console.earlySetup has loaded the Dvorak keymap (base/locale.nix):
# one prompt, Dvorak, and LUKS can keep cryptsetup's default argon2id, which
# GRUB 2.12 cannot read. Kernels and initrds are in the clear, as on Arch.
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
                # Holds every kernel/initrd pair GRUB can boot; see
                # configurationLimit below.
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
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
                  # null => interactive prompt (local ISO install).
                  passwordFile = cfg.passwordFile;

                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ]; # force overwrite any existing filesystem
                    subvolumes = {
                      # Snapshotted by snapper (config "root")
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

    # Every NixOS generation keeps its kernel + initrd on the 1 G ESP. Cap the
    # GRUB menu so old ones are removed before it fills up.
    boot.loader.grub.configurationLimit = 10;

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
