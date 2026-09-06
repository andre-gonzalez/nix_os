# KVM/QEMU/libvirt — mirrors roles/heavy_workstation (libvirt group)
{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;      # TPM emulation for Windows 11
      # ovmf.enable was removed upstream: the `virtualisation.libvirtd.qemu.ovmf`
      # submodule is gone, and all OVMF images distributed with QEMU are now
      # available by default. Setting it is a hard assertion failure.
    };
  };

  programs.virt-manager.enable = true;

  users.users.frank.extraGroups = [ "libvirtd" "kvm" ];

  environment.systemPackages = with pkgs; [
    virt-viewer
    spice-gtk
    swtpm
  ];
}
