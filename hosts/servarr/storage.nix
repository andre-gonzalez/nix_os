# Where the stacks keep data (servarr repo, CLAUDE.md "Layout"):
#   /srv/servarr/<service>  every service's writable state (DATA_ROOT in .env)
#   /mnt/media              the media library over NFS: downloads/, tvshows/,
#                           movies/, music/, books/
{ ... }:
{
  # Same export and options as Debian's /etc/fstab.
  fileSystems."/mnt/media" = {
    device = "192.168.100.76:/mnt/media";
    fsType = "nfs";
    options = [ "defaults" "_netdev" ];
  };

  # The *arr apps, qBittorrent and Jellyfin bind-mount /mnt/media. If dockerd
  # started without the mount they would see the empty mountpoint on the root
  # disk, and qBittorrent would download into it. So docker waits for it, and
  # does not start at all if the NAS is unreachable at boot — Pi-hole too.
  systemd.services.docker.unitConfig.RequiresMountsFor = [ "/mnt/media" ];

  # Only the parent: each service's dir is created by hand before the stack
  # that uses it is deployed (servarr CLAUDE.md, "Adding a new service"), or
  # comes with the data copied from Debian.
  systemd.tmpfiles.settings.servarr-data."/srv/servarr".d = {
    user = "frank";
    group = "frank";
    mode = "0755";
  };
}
