{ config, pkgs, inputs, customPkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware/btrfs.nix
    # Full-disk encryption, same layout as t14: LUKS2 + btrfs with the swapfile
    # inside, /boot on the ESP, one Dvorak passphrase prompt in the initrd. No
    # hibernation (the old plaintext 16 G swap partition with resumeDevice is
    # gone).
    ../../modules/nixos/hardware/disko-btrfs-luks.nix
    ../../modules/nixos/hardware/intel.nix
    # TLP: shared settings + intel_pstate specifics. No ThinkPad module here —
    # this machine has no EC charge thresholds or ACPI platform profile.
    ../../modules/nixos/hardware/power.nix
    ../../modules/nixos/hardware/power-intel.nix
    ../../modules/nixos/services/tailscale.nix
    # Containers and VMs, as on Arch (the Ansible samsung_expert tag also ran
    # heavy_workstation).
    ../../modules/nixos/services/docker.nix
    ../../modules/nixos/virtualization/libvirt.nix
  ];

  networking.hostName = "samsung-expert";

  # The only host with a second, spinning SATA disk. This serial used to be
  # written to /etc/tlp.conf on *every* notebook by the Ansible role, including
  # machines that have no SATA controller at all.
  services.tlp.settings = {
    DISK_DEVICES = "ata-WDC_WDS240G2G0B-00EPW0_193994801333";
    DISK_SPINDOWN_TIMEOUT_ON_AC = "0 0";
    DISK_SPINDOWN_TIMEOUT_ON_BAT = "0 12";
    DISK_APM_LEVEL_ON_AC = "254 254";
    DISK_APM_LEVEL_ON_BAT = "128 128";
    SATA_LINKPWR_ON_AC = "med_power_with_dipm";
    SATA_LINKPWR_ON_BAT = "min_power";
  };

  # WiFi: Qualcomm Atheros QCA9377 [168c:0042] — free, in-kernel ath10k_pci
  # driver (auto-loads via PCI, no boot.kernelModules pin needed). It only
  # needs the QCA firmware shipped in linux-firmware. This machine is NOT
  # Broadcom — the old broadcom_sta / "wl" / permittedInsecurePackages config
  # was carried over from the previous host and has been removed.
  hardware.enableRedistributableFirmware = true;

  # WiFi (iwd + known networks): modules/nixos/desktop/wifi.nix. The QUEWIFI-5G
  # profile lets this machine auto-connect headless on first boot (no wired
  # fallback); agenix decrypts it with the host key injected via --extra-files.

  # Hybrid graphics: Intel UHD 620 (drives the laptop panel) + discrete NVIDIA
  # MX110 [10de:174e]. nouveau was claiming /dev/dri/card0 (the NVIDIA GPU,
  # which has NO connected outputs), so Xorg auto-selected it and died with
  # "modeset(0): No modes / no screens found". We run dwm on the iGPU and do
  # not use the dGPU, so disable nouveau — the Intel GPU then becomes card0 and
  # Xorg drives the panel. (If PRIME offload for the dGPU is ever wanted, wire
  # modules/nixos/hardware/nvidia.nix instead.)
  boot.blacklistedKernelModules = [ "nouveau" "nvidiafb" ];
  services.xserver.videoDrivers = [ "modesetting" ];

  # Mount points for internal drives.
  # NOTE: these partition UUIDs belong to the OLD machine. Re-add / update them
  # only if the new machine actually has these drives (check `blkid`).
  # fileSystems."/mnt/hd-interno" = {
  #   device = "/dev/disk/by-partuuid/72749a9f-5496-4700-ad5e-f4f2eaad8da5";
  #   fsType = "ext4";
  #   options = [ "defaults" "nofail" ];
  # };

  # fileSystems."/mnt/ntfs-hd-interno" = {
  #   device = "/dev/disk/by-partuuid/f41cf00e-dbf1-431f-a833-9f9e20ebed89";
  #   fsType = "ntfs3";
  #   options = [ "defaults" "nofail" ];
  # };

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = false;
    default = "saved";
    timeout = 1;
    # Samsung UEFI firmware does not reliably honor a custom NVRAM boot entry
    # (symptom: "no bootable device", no GRUB menu). Install GRUB to the
    # removable-media fallback path (\EFI\BOOT\BOOTX64.EFI), which firmware
    # always tries. Mutually exclusive with canTouchEfiVariables, so that is
    # set to false below.
    efiInstallAsRemovable = true;
  };
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot"; # matches disko-btrfs-luks.nix ESP mount

  boot.kernelParams = [
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
    "audit=1"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.frank = import ../../modules/home;
    extraSpecialArgs = { inherit inputs customPkgs; };
  };

  system.stateVersion = "25.05";
}
