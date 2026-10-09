# Hourly push of the Radicale collections (calendars, contacts) to their
# private GitHub mirror — the network half of stacks/radicale's versioning.
# The in-container hook only commits, so a slow GitHub never stalls a save.
# Replaces the servarr repo's stacks/radicale/systemd/radicale-git-push.*,
# which were copied into /etc/systemd/system by hand on Debian.
#
# The deploy key (write access to that one mirror repo) is Debian's
# ~/.ssh/radicale_deploy, in agenix. GIT_SSH_COMMAND overrides the repo's own
# core.sshCommand, which still names the Debian path. Without the secret, that
# core.sshCommand applies unchanged.
{ lib, pkgs, ... }:
let
  collections = "/srv/servarr/radicale/collections";
  keySecret = ../../secrets/servarr-radicale-deploy.age;
  hasKey = builtins.pathExists keySecret;
in
{
  age.secrets = lib.optionalAttrs hasKey {
    servarr-radicale-deploy = {
      file = keySecret;
      owner = "frank";
      group = "frank";
      mode = "0400";
    };
  };

  systemd.services.radicale-git-push = {
    description = "Push Radicale collections to the private GitHub mirror";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    # Before the data is copied from Debian there is nothing to push.
    unitConfig.ConditionPathExists = "${collections}/.git";
    path = [ pkgs.git pkgs.openssh ];
    environment = lib.optionalAttrs hasKey {
      GIT_SSH_COMMAND =
        "ssh -i /run/agenix/servarr-radicale-deploy -o IdentitiesOnly=yes -o ConnectTimeout=10";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "frank";
      Group = "frank";
      WorkingDirectory = collections;
      ExecStart = "${pkgs.git}/bin/git push --quiet origin HEAD";
      TimeoutStartSec = 120;
      Nice = 10;
    };
  };

  systemd.timers.radicale-git-push = {
    description = "Hourly push of Radicale collections to GitHub";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      # Catch up after downtime instead of silently skipping the missed run.
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
}
