# Disko disk layout for servers: ESP + one ext4 root. No LUKS (a server must
# boot unattended after a power cut), no swap partition, no snapshots.
#
# WARNING: applying this ERASES the entire target disk (default /dev/sda).
# Override the device per-host with:  disko.devices.disk.main.device = "/dev/vda";
{ lib, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          priority = 2;
          name = "root";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
  };
}
