# CI deploys of THIS repo to servarr: on a push to main, .github/workflows/
# build.yaml joins the tailnet as tag:ci and runs, over SSH as `nixdeploy`,
#   deploy <sha>    -> exit 4: activated with `test`, a revert timer armed
#   confirm <sha>   -> a fresh connection got through: make it the boot default
# The same model as the servarr repo's own pipeline: CI can only name a
# commit on main; the server fetches the public repo, builds and switches
# itself (nixos-deploy.sh). A config that cuts CI off is switched back by the
# timer.
#
# `nixdeploy` reaches root only through one sudo rule for that one script.
# Its key is pinned to it twice (authorized_keys command= and the Match
# block's ForceCommand) and accepted from Tailscale addresses only.
{ config, lib, pkgs, ... }:
let
  revertAfter = "5min";
  healthUnits = [ "sshd.service" "tailscaled.service" "docker.service" ];

  deployScript = pkgs.writeShellApplication {
    name = "servarr-nixos-deploy";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.util-linux # flock
      config.nix.package
      config.systemd.package
    ];
    text = lib.replaceStrings
      [ "@repoUrl@" "@attr@" "@revertAfter@" "@healthUnits@" ]
      [
        "https://github.com/andre-gonzalez/nix_os.git"
        "servarr"
        revertAfter
        (lib.concatStringsSep " " healthUnits)
      ]
      (builtins.readFile ./nixos-deploy.sh);
  };

  # The forced command. The client's command line arrives in
  # $SSH_ORIGINAL_COMMAND and is passed on as one argument. A script rather
  # than an inline `sudo … "$SSH_ORIGINAL_COMMAND"`: the openssh module's
  # sshd_config generation expands $VARS, which emptied it.
  forced = toString (pkgs.writeShellScript "servarr-nixos-deploy-ssh" ''
    exec /run/wrappers/bin/sudo -n ${deployScript}/bin/servarr-nixos-deploy "''${SSH_ORIGINAL_COMMAND:-}"
  '');

  # Public half of the key in the nix_os repo secret DEPLOY_SSH_KEY.
  ciKeyFile = ./nixos-deploy-ci.pub;
  ciKey = lib.optionalString (builtins.pathExists ciKeyFile)
    (lib.removeSuffix "\n" (builtins.readFile ciKeyFile));
in
{
  # The server evaluates and builds a flake itself.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Every deploy leaves a generation behind.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  users.groups.nixdeploy = { };
  users.users.nixdeploy = {
    isSystemUser = true;
    description = "nix_os CI/CD (servarr-nixos-deploy via forced command)";
    group = "nixdeploy";
    shell = pkgs.bash;
    hashedPassword = "*"; # no password, but not locked (see deploy.nix)
    openssh.authorizedKeys.keys = lib.optional (ciKey != "")
      ''restrict,from="100.64.0.0/10,fd7a:115c:a1e0::/48",command="${forced}" ${ciKey}'';
  };

  local.ssh.extraAllowUsers = [ "nixdeploy" ];

  services.openssh.extraConfig = lib.mkAfter ''
    # nix_os CI/CD: key only (no TOTP), one command, nothing else.
    Match User nixdeploy
        AuthenticationMethods publickey
        PubkeyAuthentication yes
        ForceCommand ${forced}
        PermitTTY no
        AllowTcpForwarding no
        AllowStreamLocalForwarding no
        AllowAgentForwarding no
        X11Forwarding no
        PermitTunnel no
  '';

  security.sudo.extraRules = [{
    users = [ "nixdeploy" ];
    commands = [{
      command = "${deployScript}/bin/servarr-nixos-deploy";
      options = [ "NOPASSWD" ];
    }];
  }];

  environment.systemPackages = [ deployScript ];
}
