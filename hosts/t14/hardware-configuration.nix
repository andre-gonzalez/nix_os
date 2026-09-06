# PLACEHOLDER — deliberately generic, and deliberately committed.
#
# A flake can only import files git knows about, and `hosts/t14/default.nix`
# imports this path unconditionally, so it has to exist *before* the real one is
# generated. Overwrite it in place on install day with:
#
#   nixos-generate-config --no-filesystems --root /mnt
#   cp /mnt/etc/nixos/hardware-configuration.nix hosts/t14/hardware-configuration.nix
#
# and commit the result. (--no-filesystems keeps disko in charge of mounts.)
#
# The remote/nixos-anywhere flow does NOT touch this file — it generates the
# friend's hardware into ./hardware-configuration.remote.nix instead, so a test
# install on foreign hardware cannot silently overwrite the real T14's.
#
# No `nixpkgs.hostPlatform` here: the flake already fixes the system, and the
# generated files set it with mkDefault — two definitions at equal priority
# would collide.
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Broad enough to reach a LUKS root on either SATA or NVMe until the real
  # scan replaces it.
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
}
