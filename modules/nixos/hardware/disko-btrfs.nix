# Disko disk layout: EFI + swap + btrfs with subvolumes.
# Used by nixos-anywhere to partition and format the disk at install time.
#
# WARNING: applying this ERASES the entire target disk (default /dev/sda).
# Override the device per-host with:  disko.devices.disk.main.device = "/dev/nvme0n1";
{ lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
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
                # Mounted at /boot/efi (not /boot) so that /boot — and therefore
                # the kernels — lives on the btrfs @ subvolume. This makes
                # grub-btrfs snapshot boot entries fully self-contained.
                mountpoint = "/boot/efi";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              priority = 2;
              name = "swap";
              size = "16G";
              content = {
                type = "swap";
                resumeDevice = true; # enables hibernation to this swap partition
              };
            };
            root = {
              priority = 3;
              name = "root";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # force overwrite any existing filesystem
                subvolumes = {
                  # Subvolume mounted at / — snapshotted by snapper (config "root")
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # Subvolume mounted at /home — snapshotted by snapper (config "home")
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # Nix store — compressed, no snapshots needed
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
