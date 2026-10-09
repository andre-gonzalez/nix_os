# Generic placeholder for a Proxmox (QEMU/KVM, OVMF) guest, so the flake
# evaluates before install day. nixos-anywhere overwrites it in place with the
# real scan (nixos-anywhere-servarr.sh passes --generate-hardware-config
# nixos-generate-config); commit that result. Filesystems come from disko
# (modules/nixos/hardware/disko-ext4.nix), not from here.
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "sd_mod"
    "sr_mod"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
