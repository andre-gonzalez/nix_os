# The servarr repo's CI/CD target: what its docs/deploy.md §2 did by hand on
# Debian, declared.
#
#   GitHub Actions ──tailnet──▶ sshd ── Match User deploy: key only, no TOTP,
#                                       ForceCommand /opt/servarr/ci/deploy.sh
#                                         └─ fetches <sha> from GitHub with a
#                                            read-only deploy key, up -d, health
#                                            gate, rollback
#
# - `deploy`: no password, no sudo, no shell beyond the forced command. In the
#   docker group, which is root-equivalent: the real limits are the forced
#   command, from= on the key and the Tailscale ACL (tag:ci → this sshd only).
# - `servarr` group: deploy's primary group; frank is in it too, so both can
#   write the checkout (core.sharedRepository=group, deploy.sh runs umask 0002).
# - /opt/servarr: cloned from GitHub on first boot by servarr-checkout.service.
#   After that only deploy.sh moves it.
# - /opt/servarr/.env: the stacks' secrets, an agenix symlink. A new ${VAR} in
#   a compose file means: update secrets/servarr-env.age here and deploy this
#   host BEFORE merging the servarr PR (its deploy refuses otherwise).
#
# Secrets are wired only once their .age file exists and is tracked
# (secrets/import-from-servarr.sh), so the host evaluates before that.
{ config, lib, pkgs, ... }:
let
  repo = "/opt/servarr";
  upstream = "git@github.com:andre-gonzalez/servarr.git";

  secret = name: ../../secrets/${name}.age;
  has = name: builtins.pathExists (secret name);

  # Public half of the key GitHub Actions logs in with (repo secret
  # DEPLOY_SSH_KEY), copied from Debian's /var/lib/deploy/.ssh/authorized_keys
  # by secrets/import-from-servarr.sh.
  ciKeyFile = ./ci-deploy-key.pub;
  ciKey = lib.optionalString (builtins.pathExists ciKeyFile)
    (lib.removeSuffix "\n" (builtins.readFile ciKeyFile));

  # agenix's default path; spelled out so the host still evaluates while the
  # secret is not imported yet.
  githubKey = "/run/agenix/servarr-github-read";
in
{
  users.groups.servarr = { };
  users.users.frank.extraGroups = [ "servarr" ];

  users.users.deploy = {
    isSystemUser = true;
    description = "servarr CI/CD (ci/deploy.sh via forced command)";
    group = "servarr";
    extraGroups = [ "docker" ];
    home = "/var/lib/deploy";
    createHome = true;
    # sshd runs the forced command through the login shell; base makes fish
    # the default, which ci/deploy.sh's quoting was never written for.
    shell = pkgs.bash;
    # No valid password, but not "!" (locked): Debian's `usermod -p '*'`.
    hashedPassword = "*";
    # from=: Tailscale addresses only. command=: pinned to the script even if
    # the Match block's ForceCommand is ever lost.
    openssh.authorizedKeys.keys = lib.optional (ciKey != "")
      ''restrict,from="100.64.0.0/10,fd7a:115c:a1e0::/48",command="${repo}/ci/deploy.sh" ${ciKey}'';
  };

  local.ssh.extraAllowUsers = [ "deploy" ];

  # Appended after base/ssh.nix's global Include/AllowUsers: a Match block runs
  # to the end of the file. SetEnv hands deploy.sh the agenix path of the
  # GitHub read key (its default is Debian's /var/lib/deploy/.ssh/github_read).
  services.openssh.extraConfig = lib.mkAfter ''
    # servarr CI/CD deploy user: key only (no TOTP), one command, nothing else.
    Match User deploy
        AuthenticationMethods publickey
        PubkeyAuthentication yes
        ForceCommand ${repo}/ci/deploy.sh
        PermitTTY no
        AllowTcpForwarding no
        AllowStreamLocalForwarding no
        AllowAgentForwarding no
        X11Forwarding no
        PermitTunnel no
        SetEnv DEPLOY_GITHUB_KEY=${githubKey}
  '';

  # GitHub's host keys (same as the servarr repo's ci/github_known_hosts),
  # system-wide: the first clone runs before that file exists, and the
  # Radicale push uses them too.
  programs.ssh.knownHosts.github = {
    hostNames = [ "github.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };

  age.secrets = lib.mkMerge [
    (lib.optionalAttrs (has "servarr-github-read") {
      # Read-only deploy key on the servarr repo (GitHub: Settings → Deploy keys).
      servarr-github-read = {
        file = secret "servarr-github-read";
        owner = "deploy";
        group = "servarr";
        mode = "0400";
      };
    })
    (lib.optionalAttrs (has "servarr-env") {
      servarr-env = {
        file = secret "servarr-env";
        path = "${repo}/.env";
        owner = "deploy";
        group = "servarr";
        mode = "0440";
      };
    })
  ];

  # Ownership as in docs/deploy.md §2.3. Mode-only 'd' lines: they create the
  # directory if missing and fix owner/mode, never touch the contents.
  systemd.tmpfiles.settings.servarr = {
    ${repo}.d = {
      user = "deploy";
      group = "servarr";
      mode = "2775";
    };
    "/var/lib/deploy".d = {
      user = "deploy";
      group = "servarr";
      mode = "0750";
    };
  };

  # First boot: clone main into /opt/servarr. Not `git clone`: the directory
  # already holds the .env symlink. Skipped once .git exists — from then on
  # only deploy.sh moves the checkout. Without the GitHub key it fails, and
  # the checkout can be made by hand (hosts/servarr/INSTALL.md).
  systemd.services.servarr-checkout = {
    description = "Clone the servarr repo into ${repo}";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "systemd-tmpfiles-setup.service" ];
    unitConfig.ConditionPathExists = "!${repo}/.git";
    path = [ pkgs.git pkgs.openssh ];
    environment.GIT_SSH_COMMAND =
      "ssh -i ${githubKey} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=30";
    serviceConfig = {
      Type = "oneshot";
      User = "deploy";
      Group = "servarr";
      UMask = "0002";
      WorkingDirectory = repo;
    };
    script = ''
      git init --quiet --initial-branch=main
      git config core.sharedRepository group
      git remote add origin ${upstream}
      git fetch --quiet origin main
      git checkout --quiet -B main --track origin/main
    '';
  };
}
