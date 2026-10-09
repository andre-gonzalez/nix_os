# SSH as frank needs the key AND a TOTP code, as on Debian
# (libpam-google-authenticator, `auth required pam_google_authenticator.so` as
# the only auth line in /etc/pam.d/sshd). The laptops are key-only.
#
# The CI `deploy` user is exempted by its own Match block (deploy.nix):
# AuthenticationMethods publickey.
#
# The TOTP seed is Debian's ~/.google_authenticator, kept in agenix so the
# authenticator app keeps working. pam_google_authenticator rewrites that file
# (DISALLOW_REUSE, rate limiting), so it cannot be a symlink into /run/agenix:
# it is seeded once, and only when missing.
#
# Lockout: without the file, SSH as frank fails (no nullok, as on Debian). The
# Proxmox console still logs in with frank's password.
{ config, lib, pkgs, ... }:
let
  seed = ../../secrets/servarr-totp.age;
  hasSeed = builtins.pathExists seed;
in
{
  services.openssh.settings = {
    # base/ssh.nix turns keyboard-interactive off for the key-only laptops.
    KbdInteractiveAuthentication = lib.mkForce true;
    AuthenticationMethods = "publickey,keyboard-interactive";
  };

  # Wanted auth stack: google_authenticator, then pam_deny — no password.
  # nixpkgs only emits the google_authenticator rule inside a block that needs
  # unixAuth = true (the openssh module sets it false, PasswordAuthentication
  # being off), so turn unixAuth on and switch its two pam_unix rules off by
  # hand. `required` would fall through to pam_deny even on a good code;
  # `sufficient` ends the stack on success, a bad code still reaches pam_deny.
  security.pam.services.sshd = {
    unixAuth = lib.mkForce true;
    googleAuthenticator.enable = true;
    rules.auth = {
      unix-early.enable = lib.mkForce false;
      unix.enable = lib.mkForce false;
      google_authenticator.control = lib.mkForce "sufficient";
    };
  };

  age.secrets = lib.optionalAttrs hasSeed {
    servarr-totp = {
      file = seed;
      owner = "frank";
      group = "frank";
      mode = "0400";
    };
  };

  system.activationScripts.servarr-totp = lib.mkIf hasSeed {
    deps = [ "agenix" "users" ];
    text = ''
      f=${config.users.users.frank.home}/.google_authenticator
      if [ ! -e "$f" ] && [ -r ${config.age.secrets.servarr-totp.path} ]; then
        ${pkgs.coreutils}/bin/install -m 0400 -o frank -g frank \
          ${config.age.secrets.servarr-totp.path} "$f"
      fi
    '';
  };
}
