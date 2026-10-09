# Mirrors roles/base/tasks/security.yml
{ pkgs, ... }:
{
  # Linux security modules, as on Arch minus AppArmor (disabled there too).
  # nixpkgs already lists landlock and yama, and appends bpf last; it turns the
  # list into the single lsm= kernel parameter. Never pass lsm= through
  # boot.kernelParams as well: the kernel only honours the last one, which
  # silently dropped lockdown and integrity.
  security.lsm = [ "lockdown" "integrity" ];

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
      "192.168.0.0/16"
    ];
    jails = {
      sshd = {
        settings = {
          enabled = true;
          # "ssh" would mean 22; the real port is a boot-time secret (ssh.nix),
          # so ban the offender on every port instead.
          port = "0:65535";
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
