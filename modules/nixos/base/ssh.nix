# Mirrors roles/base/tasks/ssh.yml
{ config, ... }:
{
  services.openssh = {
    enable = true;
    # Port is decrypted at runtime from agenix secret.
    # Uncomment once secrets are wired up:
    # ports = [ (lib.toInt config.age.secrets.ssh-port.value) ];
    ports = [ 22 ]; # placeholder — override per-host or via agenix

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
    };

    # Legal warning banner
    banner = "/etc/issue.net";

    # Restrict login to frank only
    extraConfig = ''
      AllowUsers frank
    '';
  };

  # Legal banner content
  environment.etc."issue.net".text = ''
    ╔══════════════════════════════════════════════════╗
    ║        AUTHORISED ACCESS ONLY                    ║
    ║  Unauthorised access is a criminal offence.      ║
    ╚══════════════════════════════════════════════════╝
  '';

  # Wire agenix secret for SSH port when secrets are populated:
  # age.secrets.ssh-port = {
  #   file = ../../secrets/ssh-port.age;
  #   owner = "root";
  # };
}
