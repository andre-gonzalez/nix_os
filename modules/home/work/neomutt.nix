# Neomutt multi-account email
# Sensitive credentials (passwords, IMAP passwords) come from agenix secrets.
# The full mutt config (muttrc, accounts/*) is managed by the dotfiles bare
# repo until migrated here. This module installs the binaries and wires secrets.
{ pkgs, config, ... }:
{
  programs.neomutt = {
    enable = true;
    # Full config lives in ~/.config/neomutt/ via dotfiles repo (Option A).
    # Once migrated, fill in the declarative config here.
  };

  # Email fetching: mbsync (isync)
  programs.mbsync = {
    enable = true;
    # mbsyncrc is an agenix secret deployed to ~/.mbsyncrc:
    # home.file.".mbsyncrc".source = config.age.secrets.mbsyncrc.path;
  };

  # Email sending: msmtp
  programs.msmtp = {
    enable = true;
    # msmtprc is an agenix secret:
    # home.file.".config/msmtp/config".source = config.age.secrets.msmtp.path;
  };

  # notmuch for email indexing (used by neomutt notmuch integration)
  programs.notmuch = {
    enable = true;
  };

  home.packages = with pkgs; [
    w3m         # HTML mail rendering
    imagemagick # inline image support
    lynx
    urlscan     # extract URLs from mails
  ];

  # agenix secrets (uncomment when secrets.nix is populated):
  # age.secrets.neomutt-personal  = { file = ../../../secrets/neomutt-personal.age;  owner = "frank"; };
  # age.secrets.neomutt-uberall   = { file = ../../../secrets/neomutt-uberall.age;   owner = "frank"; };
  # age.secrets.neomutt-athenaworks = { file = ../../../secrets/neomutt-athenaworks.age; owner = "frank"; };
  # age.secrets.msmtp              = { file = ../../../secrets/msmtp.age;             owner = "frank"; };
  # age.secrets.mbsyncrc           = { file = ../../../secrets/mbsyncrc.age;          owner = "frank"; };
}
