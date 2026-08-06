{ config, pkgs, inputs, customPkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware/btrfs.nix
    ../../modules/nixos/hardware/disko-btrfs.nix
    ../../modules/nixos/hardware/intel.nix
    ../../modules/nixos/hardware/power.nix
    ../../modules/nixos/services/tailscale.nix
  ];

  networking.hostName = "samsung-expert";

  # WiFi: Qualcomm Atheros QCA9377 [168c:0042] — free, in-kernel ath10k_pci
  # driver (auto-loads via PCI, no boot.kernelModules pin needed). It only
  # needs the QCA firmware shipped in linux-firmware. This machine is NOT
  # Broadcom — the old broadcom_sta / "wl" / permittedInsecurePackages config
  # was carried over from the previous host and has been removed.
  hardware.enableRedistributableFirmware = true;

  # WiFi via iwd (replaces wpa_supplicant; gives us `iwctl` for roaming). iwd
  # lets its built-in DHCP client configure the link and hands DNS to
  # systemd-resolved.
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = true; # iwd runs DHCP
      Network.NameResolvingService = "systemd";  # integrate with systemd-resolved
    };
  };

  # Seed the home network as an iwd profile so the machine auto-connects headless
  # on first boot (no wired fallback). agenix decrypts the profile (using the
  # host key injected at install via --extra-files) directly to
  # /var/lib/iwd/QUEWIFI-5G.psk — a real file (symlink = false) with 0600 perms,
  # as iwd requires. Additional networks are added at runtime with `iwctl`.
  systemd.tmpfiles.rules = [
    # Ensure iwd's state dir exists before agenix places the profile in it
    # (agenix runs during activation, before iwd.service creates StateDirectory).
    "d /var/lib/iwd 0700 root root -"
  ];
  age.secrets."iwd-QUEWIFI-5G" = {
    file = ../../secrets/iwd-QUEWIFI-5G.age;
    path = "/var/lib/iwd/QUEWIFI-5G.psk";
    mode = "0600";
    owner = "root";
    group = "root";
    symlink = false; # iwd needs a real file with strict perms, not a symlink
  };

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
  boot.loader.efi.efiSysMountPoint = "/boot/efi"; # matches disko-btrfs.nix ESP mount

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
