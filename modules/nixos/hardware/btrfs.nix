# Btrfs kernel support, grub-btrfs, and snapper
# Mirrors roles/light_workstation/tasks/snapper.yml + grub.yml
{ config, lib, pkgs, ... }:
let
  # Snapper configs that declare a QGROUP, so the setup service below and the
  # SPACE_LIMIT/FREE_LIMIT settings never drift apart.
  quotaConfigs = lib.filterAttrs (_: c: c ? QGROUP) config.services.snapper.configs;

  # Snapshot retention shared by every config. Snapper keeps the newest N
  # snapshots in each timeline bucket independently, so these add up: 12
  # timeline snapshots per config. The long-horizon buckets are deliberately
  # 0 — a year-old snapshot pins every block changed since it was taken, which
  # on a workstation is most of the filesystem, and that space cannot be
  # reclaimed while the snapshot exists.
  retention = {
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_MIN_AGE = "1800";
    TIMELINE_LIMIT_HOURLY = "5";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "0";
    TIMELINE_LIMIT_MONTHLY = "0";
    TIMELINE_LIMIT_QUARTERLY = "0";
    TIMELINE_LIMIT_YEARLY = "0";

    # Nothing on NixOS creates number-cleanup snapshots the way snap-pac does
    # around pacman transactions, so this is a bound on anything that starts
    # doing so later (a nixos-rebuild wrapper, a manual `snapper create -c
    # number`) rather than a limit that bites today. Set explicitly because
    # snapper's own built-in default for NUMBER_CLEANUP is not what the Arch
    # config templates ship.
    NUMBER_CLEANUP = true;
    NUMBER_MIN_AGE = "1800";
    NUMBER_LIMIT = "10";
    NUMBER_LIMIT_IMPORTANT = "5";

    # Fractions of the filesystem: snapshots may occupy up to 30%, and cleanup
    # gets more aggressive below 20% free. Both are ignored unless the config
    # owns a btrfs qgroup — see snapper-setup-quota below.
    SPACE_LIMIT = "0.3";
    FREE_LIMIT = "0.2";
  };
in
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
      root = retention // {
        SUBVOLUME = "/";
        ALLOW_USERS = [ "frank" ];
        QGROUP = "1/0";
      };
      home = retention // {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ "frank" ];
        # A distinct level-1 qgroup: / and /home are subvolumes of the same
        # filesystem, so they cannot share one. These are the ids `snapper
        # setup-quota` picks for the two configs on its own.
        QGROUP = "1/1";
      };
    };
  };

  # The space limits above are only consulted when the config owns a btrfs
  # qgroup, and nothing creates one automatically. The usual `snapper
  # setup-quota` is unusable here: it writes QGROUP back into
  # /etc/snapper/configs/<name>, which on NixOS is a read-only symlink into the
  # store. So the id is declared above and only the filesystem-side state —
  # quota enabled, qgroup present — is reconciled here.
  systemd.services.snapper-setup-quota = lib.mkIf (quotaConfigs != { }) {
    description = "Ensure btrfs qgroups backing the snapper space limits exist";
    documentation = [ "man:snapper-configs(5)" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    before = [ "snapper-cleanup.service" ];
    # gawk as well as btrfs-progs: systemd's default unit PATH carries
    # coreutils/findutils/gnugrep/gnused but NOT awk, and the probe below calls
    # it. Without this the probe dies with 127, `if !` reads that as "qgroup
    # absent", and the service then tries to create a qgroup that already
    # exists — failing every boot, with the space limits never enforced.
    path = [ pkgs.btrfs-progs pkgs.gawk ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail

      ensure_qgroup() {
        subvolume="$1"
        qgroup="$2"

        # Idempotent once enabled, but the very first run schedules a quota
        # rescan, which is I/O heavy on a filesystem that is already full.
        btrfs quota enable "$subvolume"

        # `btrfs qgroup create` exits non-zero when the qgroup already exists,
        # so probe for it rather than swallowing every failure with `|| true`.
        # awk does the matching and terminates the pipeline: piping into
        # `grep -q` would let grep exit on the first hit, SIGPIPE the writer and
        # trip `pipefail` into reporting "not found" for a qgroup that is
        # present. Every snapshot is a subvolume, so that list is always long
        # enough for the race to land.
        if ! btrfs qgroup show "$subvolume" | awk -v q="$qgroup" '$1 == q { found = 1 } END { exit !found }'; then
          btrfs qgroup create "$qgroup" "$subvolume"
        fi
      }

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          _: c: "ensure_qgroup ${lib.escapeShellArg c.SUBVOLUME} ${lib.escapeShellArg c.QGROUP}"
        ) quotaConfigs
      )}
    '';
  };

  environment.systemPackages = with pkgs; [
    btrfs-progs
    btrfs-assistant # GUI snapshot manager (AUR: btrfs-assistant)
  ];
}
