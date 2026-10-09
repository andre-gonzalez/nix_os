# Mirrors roles/base/tasks/ssh.yml
#
# The listening port is a secret (secrets/ssh-port.age, the Ansible vault's
# `ssh_port`), so it cannot appear in the Nix config: the repo is public and
# NixOS would need the value at build time. Instead it is resolved at boot:
#
#   ssh-port.service reads /run/agenix/ssh-port and
#     1. writes "Port N" to /run/sshd-port/port.conf, which sshd_config Includes
#        (services.openssh.ports is empty, so there is no other Port line);
#     2. puts N into the nftables set inet nixos-fw ssh_port, which the LAN
#        rule in firewall.nix matches on.
#
# Every nftables reload deletes and recreates the nixos-fw table, emptying the
# set, so the service re-runs on each reload/restart of nftables.service.
#
# Without the secret (not yet imported, or t14-remote, which clears
# age.secrets) or with an invalid value, the port is 22. If the service fails
# outright, sshd falls back to its built-in 22 while the set stays empty —
# SSH is unreachable rather than exposed.
{ config, lib, pkgs, ... }:
let
  portSecret = ../../../secrets/ssh-port.age;
  secretPath = lib.attrByPath [ "ssh-port" "path" ] null config.age.secrets;
  portConf = "/run/sshd-port/port.conf";

  setPort = pkgs.writeShellScript "ssh-port" ''
    set -eu
    port=
    ${lib.optionalString (secretPath != null) ''
      [ -r ${secretPath} ] && port=$(tr -d '[:space:]' < ${secretPath})
    ''}
    case $port in
      "" | *[!0-9]*) port= ;;
    esac
    if [ -z "$port" ] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
      ${lib.optionalString (secretPath != null) ''echo "ssh-port: secret missing or invalid, using 22" >&2''}
      port=22
    fi

    printf 'Port %s\n' "$port" > ${portConf}.tmp
    mv ${portConf}.tmp ${portConf}

    ${pkgs.nftables}/bin/nft flush set inet nixos-fw ssh_port
    ${pkgs.nftables}/bin/nft add element inet nixos-fw ssh_port "{ $port }"
  '';
in
{
  services.openssh = {
    enable = true;

    # No Port line from the module; the Include below supplies it.
    ports = [ ];
    # openFirewall would add the port to the *global* allow list, bypassing the
    # LAN-only rule in firewall.nix (with ports = [ 22 ] it used to open 22 to
    # every network this laptop joins).
    openFirewall = false;

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      AllowTcpForwarding = false;
      AllowAgentForwarding = false;
      MaxAuthTries = 3;
      MaxSessions = 2;
      ClientAliveCountMax = 2;
      TCPKeepAlive = false;
      LogLevel = "VERBOSE";
      # Legal warning banner (`banner` was renamed to settings.Banner)
      Banner = "/etc/issue.net";
    };

    # Restrict login to frank only. The Include must stay in the global section
    # (before any Match block); a missing file is silently skipped by sshd.
    extraConfig = ''
      Include ${portConf}
      AllowUsers frank
    '';
  };

  age.secrets = lib.optionalAttrs (builtins.pathExists portSecret) {
    ssh-port = {
      file = portSecret;
      owner = "root";
      mode = "0400";
    };
  };

  # Declared ahead of the chains so the input-allow rule can reference it.
  networking.nftables.tables."nixos-fw".content = lib.mkBefore ''
    set ssh_port {
      type inet_service
    }
  '';

  systemd.services.ssh-port = {
    description = "Apply the SSH port from the agenix secret";
    wantedBy = [ "multi-user.target" ];
    requiredBy = [ "sshd.service" ];
    before = [ "sshd.service" ];
    after = [ "nftables.service" ];
    requires = [ "nftables.service" ];
    partOf = [ "nftables.service" ]; # re-run after an nftables restart
    unitConfig.ReloadPropagatedFrom = [ "nftables.service" ]; # ...and reload
    # A new secret value changes the .age store path: re-run, restart sshd.
    restartTriggers = lib.optional (secretPath != null) portSecret;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = setPort;
      ExecReload = setPort;
      RuntimeDirectory = "sshd-port";
      RuntimeDirectoryPreserve = "yes"; # sshd re-reads it on every restart
    };
  };

  systemd.services.sshd.restartTriggers = lib.optional (secretPath != null) portSecret;

  # Legal banner content
  environment.etc."issue.net".text = ''
    ╔══════════════════════════════════════════════════╗
    ║        AUTHORISED ACCESS ONLY                    ║
    ║  Unauthorised access is a criminal offence.      ║
    ╚══════════════════════════════════════════════════╝
  '';
}
