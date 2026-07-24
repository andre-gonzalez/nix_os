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
  networking.wireless.enable = true; # wpa_supplicant

  # WiFi credentials via agenix. The raw PSK lives in an age-encrypted file
  # decrypted at boot to config.age.secrets.wifi-queWifi2.path
  # (/run/agenix/wifi-queWifi2), which contains: queWifi2_psk=<64-hex-psk>.
  # wpa_supplicant reads it through ext_password_backend (the "ext:" ref).
  # Decryption uses the host key injected at install via --extra-files, so
  # the network is available on the very first boot — required because this
  # machine has no wired fallback.
  age.secrets.wifi-queWifi2 = {
    file = ../../secrets/wifi-queWifi2.age;
    # NixOS runs wpa_supplicant as the unprivileged "wpa_supplicant" user under
    # systemd hardening (not root), so the decrypted secret must be owned by it.
    # Otherwise the service fails with:
    #   EXT PW FILE: could not open file '/run/agenix/wifi-queWifi2': Permission denied
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
  };
  networking.wireless.secretsFile = config.age.secrets.wifi-queWifi2.path;
  networking.wireless.networks."QUEWIFI-5G".pskRaw = "ext:queWifi2_psk";

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
