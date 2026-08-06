# Btrfs kernel support, grub-btrfs, and snapper
# Mirrors roles/light_workstation/tasks/snapper.yml + grub.yml
{ pkgs, ... }:
{
  boot.supportedFilesystems = [ "btrfs" ];

  # NOTE: grub-btrfs (which injected snapshot boot entries into GRUB) was
  # removed from nixpkgs-unstable — both the `services.grub-btrfs` module and
  # the package no longer exist. Snapper snapshots/rollback below still work
  # from a running system; there is just no snapshot boot menu in GRUB.

  # Auto-scrub btrfs filesystems monthly
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };

  # snapper configs — mirrors `snapper createconfig` calls in the Ansible role
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    configs = {
      root = {
        SUBVOLUME = "/";
        ALLOW_USERS = [ "frank" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_MIN_AGE = "1800";
        TIMELINE_LIMIT_HOURLY = "5";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "0";
        TIMELINE_LIMIT_MONTHLY = "0";
        TIMELINE_LIMIT_YEARLY = "0";
      };
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ "frank" ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_MIN_AGE = "1800";
        TIMELINE_LIMIT_HOURLY = "5";
        TIMELINE_LIMIT_DAILY = "7";
        TIMELINE_LIMIT_WEEKLY = "0";
        TIMELINE_LIMIT_MONTHLY = "0";
        TIMELINE_LIMIT_YEARLY = "0";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
    btrfs-assistant # GUI snapshot manager (AUR: btrfs-assistant)
  ];
}
