# Declarative Windows VM definition via libvirt XML
# Import this module on hosts where the Windows VM should be defined.
# The actual VM disk image must exist at the path below.
{ pkgs, lib, ... }:
{
  # Placeholder — fill in after the VM is initially created with virt-manager
  # and the XML exported with `virsh dumpxml <domain>`
  #
  # systemd.services."libvirt-vm-windows" = {
  #   description = "Windows VM (libvirt)";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "libvirtd.service" ];
  #   path = [ pkgs.libvirt ];
  #   script = ''
  #     virsh define /etc/libvirt/qemu/windows.xml
  #   '';
  #   serviceConfig.Type = "oneshot";
  #   serviceConfig.RemainAfterExit = true;
  # };
}
