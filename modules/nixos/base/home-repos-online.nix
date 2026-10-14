# Re-run frank's home-manager activation once the network is up, so the repo
# clones in modules/home/{repos,scripts}.nix (dotfiles, ~/.scripts, notas,
# windows-docker) are not left missing after a boot without network.
#
# home-manager-frank.service runs early in boot, ordered before
# systemd-user-sessions. On WiFi, iwd has not joined a network yet, so every
# clone fails with "Could not resolve host: github.com" — and on the next boot
# the same race repeats, so a fresh install never gets its dotfiles.
# network-online.target does not help: iwd runs its own DHCP and has no
# wait-online service, so the target is reached before there is a link.
# Instead, poll DNS for github.com.
#
# Only acts when one of the clones is missing, and does not hold up the boot or
# the login (Type=simple, not ordered before anything).
{ config, lib, pkgs, ... }:
let
  home = "/home/frank";
  # Keep in sync with the clone targets in modules/home/{repos,scripts}.nix.
  clones = [
    "${home}/.config/dotfiles"
    "${home}/.scripts"
    "${home}/projects/notas"
    "${home}/projects/windows-docker"
  ];
  hasHomeManager = lib.attrByPath [ "home-manager" "users" "frank" ] null config != null;
in
{
  systemd.services.home-manager-frank-online = lib.mkIf hasHomeManager {
    description = "Re-run frank's home-manager activation once github.com resolves";
    wantedBy = [ "multi-user.target" ];
    after = [ "home-manager-frank.service" ];
    serviceConfig.Type = "simple";
    script = ''
      missing=0
      for p in ${lib.escapeShellArgs clones}; do
        [ -e "$p" ] || missing=1
      done
      [ "$missing" = 1 ] || exit 0

      # Up to 10 minutes; give up quietly after that (the next boot or
      # rebuild tries again).
      for _ in $(seq 120); do
        if ${pkgs.getent}/bin/getent hosts github.com >/dev/null; then
          exec ${config.systemd.package}/bin/systemctl restart home-manager-frank.service
        fi
        sleep 5
      done
      echo "github.com still does not resolve; repo clones not retried"
    '';
  };
}
