# GnuPG agent with a graphical pinentry (dwm/X session), and the secret-key
# export the home-manager side (home/gpg.nix) imports from. Arch's
# /usr/bin/pinentry wrapper picked a GUI flavour the same way.
{ lib, pkgs, ... }:
let
  keys = ../../../secrets/gpg-secret-keys.age;
in
{
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };

  age.secrets = lib.optionalAttrs (builtins.pathExists keys) {
    gpg-secret-keys = {
      file = keys;
      owner = "frank";
      mode = "0400";
    };
  };
}
