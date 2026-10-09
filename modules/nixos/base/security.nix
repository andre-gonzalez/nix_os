# Mirrors roles/base/tasks/security.yml
{ config, lib, pkgs, ... }:
let
  # pam_faillock the way Arch's system-auth wires it (roles/light_workstation/
  # tasks/faillock.yml only set deny/unlock_time in faillock.conf): `preauth`
  # refuses a locked account before anything is asked, `authfail` records a
  # failed password, and the account phase clears the tally after a success.
  # Placed relative to each service's own unix rule, whose order differs per
  # service. Arch applied it to everything including system-auth — login, su,
  # sudo; slock had no PAM file there, so it is not locked out here either.
  faillock = "${config.security.pam.package}/lib/security/pam_faillock.so";
  withFaillock = name: {
    rules = let r = config.security.pam.services.${name}.rules; in {
      auth.faillock-preauth = {
        order = r.auth.unix.order - 2000;
        control = "required";
        modulePath = faillock;
        args = [ "preauth" ];
      };
      auth.faillock-authfail = {
        order = r.auth.unix.order + 10;
        control = "[default=die]";
        modulePath = faillock;
        args = [ "authfail" ];
      };
      account.faillock = {
        order = r.account.unix.order - 10;
        control = "required";
        modulePath = faillock;
      };
    };
  };
in
{
  # Root cannot log in at all, only act through sudo (Security.yml:
  # "Disable root login"). Without this root got fish via defaultUserShell.
  users.users.root.shell = "${pkgs.shadow}/bin/nologin";

  security.pam.services = lib.genAttrs [ "login" "su" "sudo" ] withFaillock;
  environment.etc."security/faillock.conf".text = ''
    deny = 5
    unlock_time = 300
  '';

  # roles/light_workstation/tasks/kernel-hardening.yml (/etc/sysctl.d/99-kernel-hardening.conf)
  boot.kernel.sysctl = {
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # ignore broadcast ICMP (smurf)
    "net.ipv4.conf.all.send_redirects" = 0;     # not a router
    "kernel.randomize_va_space" = 2;            # full ASLR
  };

  # ClamAV (roles/light_workstation/tasks/security.yml) is workstation-only:
  # ../workstation/clamav.nix.

  # Linux security modules, as on Arch minus AppArmor (disabled there too).
  # nixpkgs already lists landlock and yama, and appends bpf last; it turns the
  # list into the single lsm= kernel parameter. Never pass lsm= through
  # boot.kernelParams as well: the kernel only honours the last one, which
  # silently dropped lockdown and integrity.
  security.lsm = [ "lockdown" "integrity" ];

  # No audit system: auditd was disabled on Arch too, so the Ansible audit
  # rules never ran, and the old catch-all execve rule logged every program
  # start. (Leaving security.audit off also keeps audit=1 off the cmdline.)

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
    # rkhunter and chkrootkit (both in Ansible) were removed from nixpkgs as
    # unmaintained. For rootkit/host auditing consider `lynis` or `aide`.
    nettools # ifconfig, netstat, route
  ];
}
