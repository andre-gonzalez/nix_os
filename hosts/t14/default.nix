# ThinkPad T14 Gen 6 (AMD) — 21QJCTO1WW, BIOS R2XET39W (1.19)
#
# Ryzen AI 7 PRO 350 (Krackan Point) + Radeon 860M [1002:1114], MT7925 WiFi,
# MediaTek BT [0e8d:e025], SOF AMD ACP7.0 + nau8821 audio, Synaptics press-type
# fingerprint reader [06cb:00f9], eDP 1920x1200 panel, HDMI-A-0 to a 2560x1080
# ultrawide when docked. s2idle only — this machine has no S3.
#
# This host replaces the old (never-installed) `workstation` host.
{ config, lib, pkgs, inputs, customPkgs, ... }:
{
  imports = [
    # Regenerated on install day and overwritten in place, either by
    #   nixos-generate-config --no-filesystems --root /mnt
    # locally, or by nixos-anywhere's --generate-hardware-config remotely.
    # (--no-filesystems keeps disko in charge of mounts.) The file in the repo
    # is a tracked generic placeholder so the flake evaluates *before* the real
    # one exists — a flake cannot import a path that is missing or untracked.
    ./hardware-configuration.nix

    ../../modules/nixos/base
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware/btrfs.nix # also provides snapper; services/snapper.nix is a re-export of this
    ../../modules/nixos/hardware/amd.nix
    # TLP: shared settings + amd-pstate specifics + the ThinkPad EC knobs
    # (charge thresholds, platform profile).
    ../../modules/nixos/hardware/power.nix
    ../../modules/nixos/hardware/power-amd.nix
    ../../modules/nixos/hardware/power-thinkpad.nix
    ../../modules/nixos/hardware/disko-btrfs-luks.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/docker.nix
    ../../modules/nixos/virtualization/libvirt.nix
    ../../modules/nixos/virtualization/windows-vm.nix

    # Deliberately NOT imported:
    #   hardware/intel.nix   — sets LIBVA_DRIVER_NAME=iHD and i915.* params globally
    #   hardware/nvidia.nix  — no discrete GPU
    #   hardware/power-intel.nix — intel_pstate specifics; power-amd.nix replaces it
    #   services/snapper.nix — thin re-export of hardware/btrfs.nix (double import)
    #   services/preload.nix — dropped
  ];

  networking.hostName = "t14";

  # Pulls both linux-firmware (MT7925 WiFi, amdgpu) and sof-firmware (ACP7.0
  # audio). Without it amdgpu will not initialize.
  hardware.enableRedistributableFirmware = true;

  # 238 GB WD SN7100. disko-btrfs-luks.nix defaults to /dev/sda.
  disko.devices.disk.main.device = "/dev/nvme0n1";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # GRUB, with /boot (and therefore every kernel and initrd) inside the LUKS
  # container. enableCryptodisk exports GRUB_ENABLE_CRYPTODISK=y so GRUB itself
  # can open the container. Lenovo firmware handles NVRAM boot entries fine, so
  # unlike the Samsung host this uses canTouchEfiVariables rather than
  # efiInstallAsRemovable.
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    enableCryptodisk = true;
    useOSProber = false;
    default = "saved";
    gfxmodeEfi = "auto";
  };
  boot.loader.timeout = 1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi"; # matches disko-btrfs-luks.nix ESP mount

  # Single passphrase prompt: GRUB asks once, then hands off to an initrd that
  # carries a keyfile for the second LUKS key slot. This is only safe because
  # /boot is itself encrypted, so the embedded key never sits in the clear.
  #
  # Gated on local.diskoLuks.useInitrdKeyFile (default true) so that the two
  # halves — the extra LUKS key slot in disko-btrfs-luks.nix and the initrd
  # secret here — can never drift apart. hosts/t14/remote-install.nix turns it
  # off: boot.initrd.secrets is resolved *during* nixos-install, before
  # nixos-anywhere gets a chance to copy --extra-files into /mnt, so an
  # unattended install cannot satisfy /boot/crypto_keyfile.bin and would abort
  # at bootloader installation. Cost of turning it off is one extra passphrase
  # prompt at boot.
  boot.initrd.secrets."/crypto_keyfile.bin" =
    lib.mkIf config.local.diskoLuks.useInitrdKeyFile "/boot/crypto_keyfile.bin";
  boot.initrd.luks.devices.cryptroot.keyFile =
    lib.mkIf config.local.diskoLuks.useInitrdKeyFile "/crypto_keyfile.bin";

  # No boot.resumeDevice / resume_offset: hibernation is deliberately not
  # configured (swap lives in a file inside LUKS, and this machine is s2idle-only).

  boot.kernelParams = [
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
    "audit=1"
  ];

  ##############################################################################
  # WiFi — MediaTek MT7925 (mt7925e), firmware from linux-firmware above.
  ##############################################################################
  # iwd rather than NetworkManager: all known networks are PSK or open, no
  # 802.1X anywhere. iwd runs its own DHCP and hands DNS to systemd-resolved.
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = true;
      Network.NameResolvingService = "systemd";
    };
  };

  systemd.tmpfiles.rules = [
    # agenix places the profile below during activation, before iwd.service
    # gets a chance to create its StateDirectory.
    "d /var/lib/iwd 0700 root root -"
  ];

  # Seed the home network so the machine auto-connects on first boot. The other
  # ~15 known networks come back by restoring /var/lib/iwd from the pre-wipe
  # backup (see INSTALL.md).
  age.secrets."iwd-QUEWIFI-5G" = {
    file = ../../secrets/iwd-QUEWIFI-5G.age;
    path = "/var/lib/iwd/QUEWIFI-5G.psk";
    mode = "0600";
    owner = "root";
    group = "root";
    symlink = false; # iwd needs a real file with strict perms, not a symlink
  };

  ##############################################################################
  # Fingerprint — Synaptics [06cb:00f9], supported by libfprint's PID table.
  ##############################################################################
  services.fprintd.enable = true;

  # Password fallback stays intact everywhere: PAM tries the finger first and
  # falls through on Ctrl-C or timeout.
  security.pam.services.sudo.fprintAuth = true;
  # This also *creates* /etc/pam.d/slock, which the PAM-enabled slock build
  # opens by name (pam_service = "slock" in the fork's config.h).
  security.pam.services.slock.fprintAuth = true;

  # login.fprintAuth is deliberately unset: services.getty.autologinUser =
  # "frank" (desktop/xorg.nix) means there is no login password prompt to
  # improve. Enrollment is a post-install step: `fprintd-enroll` as frank.

  ##############################################################################
  # Laptop behaviours
  ##############################################################################
  # Lock the X session before sleeping. Nothing equivalent existed on Arch —
  # only xautolock's 10-minute idle timer, so a closed lid was an unlocked
  # machine. Type is "simple", not "forking": slock never daemonizes, so a
  # forking unit would hang the whole sleep transition waiting for a fork that
  # never comes. With "simple" the unit is active as soon as slock execs,
  # sleep.target proceeds, and slock stays up as the lock screen until unlocked.
  systemd.services.slock-suspend = {
    description = "Lock X session with slock before sleep";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    environment = {
      DISPLAY = ":0";
      XAUTHORITY = "/home/frank/.Xauthority"; # startx from tty1, no display manager
    };
    serviceConfig = {
      Type = "simple";
      User = "frank";
      ExecStart = "/run/wrappers/bin/slock"; # setuid wrapper from desktop/xorg.nix
    };
  };

  # These are already the logind defaults; set explicitly as documentation of
  # intent. HandleLidSwitchDocked applies whenever an external display is
  # connected — i.e. the docked-with-ultrawide case.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "suspend";
  };

  # brightnessctl is in systemPackages (desktop/xorg.nix) but that does not
  # install its udev rules, so XF86MonBrightness* had no way to touch
  # amdgpu_bl1 without root. frank is already in the `video` group
  # (base/users.nix). Key bindings live in ~/.xbindkeysrc in the dotfiles repo.
  services.udev.packages = [ pkgs.brightnessctl ];

  # Lenovo ships T14 UEFI, EC and Synaptics fingerprint firmware through LVFS.
  services.fwupd.enable = true;

  ##############################################################################
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.frank = import ../../modules/home;
    extraSpecialArgs = { inherit inputs customPkgs; };
  };

  system.stateVersion = "25.05"; # set once, do not update
}
