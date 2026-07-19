# Minimal hardware configuration stub.
#
# Filesystems, swap and the boot ESP are all defined by disko
# (modules/nixos/hardware/disko-btrfs.nix), so they are intentionally NOT here.
#
# RECOMMENDED: let nixos-anywhere regenerate this from the real hardware:
#   nixos-anywhere --generate-hardware-config nixos-generate-config \
#     ./hosts/samsung-expert/hardware-configuration.nix \
#     --flake .#samsung-expert --target-host root@<target-ip>
# That overwrites this file with the correct modules for the new machine
# (while --no-filesystems keeps disko in charge of mounts).
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Generic SATA/USB boot modules — safe defaults for a /dev/sda install.
  # Regenerate (see above) to match the real machine precisely.
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
