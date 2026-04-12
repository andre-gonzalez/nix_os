# KVM/QEMU/libvirt — mirrors roles/heavy_workstation (libvirt group)
{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;      # TPM emulation for Windows 11
      ovmf.enable = true;       # UEFI firmware for VMs
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
