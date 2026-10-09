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

  # virsh & co. as frank talk to the system daemon by default, not to a
  # per-user qemu:///session with no VMs (roles/heavy_workstation/tasks/
  # Libvirt.yml set uri_default in both files). A non-root client only reads
  # its XDG copy; root already defaults to qemu:///system.
  home-manager.users.frank.xdg.configFile."libvirt/libvirt.conf".text = ''
    uri_default = "qemu:///system"
  '';

  environment.systemPackages = with pkgs; [
    virt-viewer
    spice-gtk
    swtpm
  ];
}
