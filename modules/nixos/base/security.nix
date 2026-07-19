# Mirrors roles/base/tasks/security.yml
{ pkgs, ... }:
{
  # AppArmor
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
  };

  # Auditd
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      "-a exit,always -F arch=b64 -S execve"
    ];
  };

  # Fail2ban — jail.local content mirrors roles/base/files/jail.local
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    ignoreIP = [
      "127.0.0.1/8"
      "::1"
      "192.168.0.0/24"
    ];
    jails = {
      sshd = {
        settings = {
          enabled = true;
          port = "ssh";
          filter = "sshd";
          maxretry = 3;
          bantime = "24h";
        };
      };
    };
  };

  # Disable core dumps
  security.pam.loginLimits = [
    { domain = "*"; item = "core"; type = "hard"; value = "0"; }
    { domain = "*"; item = "core"; type = "soft"; value = "0"; }
  ];

  # Password policy (mirrors /etc/login.defs)
  security.loginDefs.settings = {
    UMASK = "027";
    PASS_MAX_DAYS = 180;
    PASS_MIN_DAYS = 1;
    PASS_WARN_AGE = 30;
    SHA_CRYPT_MIN_ROUNDS = 5000;
  };

  # Additional hardening packages
  environment.systemPackages = with pkgs; [
    # rkhunter was removed from nixpkgs. For rootkit/host auditing consider
    # `lynis` or `aide` (both still packaged) instead.
    sysstat
  ];
}
