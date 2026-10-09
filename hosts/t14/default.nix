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
    #   services/preload.nix — gone: preload was removed from nixpkgs (broken)
  ];

  networking.hostName = "t14";

  # Pulls both linux-firmware (MT7925 WiFi, amdgpu) and sof-firmware (ACP7.0
  # audio). Without it amdgpu will not initialize.
  hardware.enableRedistributableFirmware = true;

  # 238 GB WD SN7100. disko-btrfs-luks.nix defaults to /dev/sda.
  disko.devices.disk.main.device = "/dev/nvme0n1";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # GRUB on the unencrypted ESP mounted at /boot; the initrd unlocks LUKS with
  # a Dvorak prompt (see disko-btrfs-luks.nix). Lenovo firmware handles NVRAM
  # boot entries fine, so unlike the Samsung host this uses
  # canTouchEfiVariables rather than efiInstallAsRemovable.
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = false;
    default = "saved";
    gfxmodeEfi = "auto";
  };
  boot.loader.timeout = 1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot"; # matches disko-btrfs-luks.nix ESP mount

  # No boot.resumeDevice / resume_offset: hibernation is deliberately not
  # configured (swap lives in a file inside LUKS, and this machine is s2idle-only).

  # No lsm= kernel param here: base/security.nix sets security.lsm, which
  # nixpkgs turns into the one lsm= param; a second one here would win and
  # drop modules.

  ##############################################################################
  # WiFi — MediaTek MT7925 (mt7925e), firmware from linux-firmware above.
  ##############################################################################
  # iwd and the known networks: modules/nixos/desktop/wifi.nix. Networks not in
  # the Ansible vault come back by restoring /var/lib/iwd from the pre-wipe
  # backup (see INSTALL.md).

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

  # brightnessctl's udev rules (backlight writable by the `video` group) are
  # installed for every desktop host in desktop/xorg.nix.

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
