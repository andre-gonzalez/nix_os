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

  # Broadcom WiFi driver (required for Samsung Expert Book)
  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  networking.wireless.enable = true; # use wpa_supplicant (or switch to iwd)

  # broadcom_sta is flagged insecure by nixpkgs and must be permitted.
  # NOTE: this string embeds the kernel version — if a kernel update changes
  # the suffix, update it to the version shown in the build error.
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.18.38"
  ];

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
  };
  boot.loader.efi.canTouchEfiVariables = true;
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
