# GPG secret keys — imported from the agenix secret "gpg-secret-keys" (an
# armored `gpg --export-secret-keys` made by secrets/export-gpg-keys.sh) when
# any of them is missing, then trusted ultimately, as on Arch. The keys stay
# protected by their own passphrases inside the export, so importing needs no
# passphrase; using them asks through the agent's pinentry
# (nixos/desktop/gnupg.nix).
#
# GNUPGHOME is set explicitly: the dotfiles (config.fish, .bash_profile) move it
# to $XDG_DATA_HOME/gnupg, but activation does not read them, so without this
# the keys land in ~/.gnupg, where no shell looks.
{ config, lib, pkgs, ... }:
let
  gpg = "${pkgs.gnupg}/bin/gpg";
  gnupghome = "${config.xdg.dataHome}/gnupg";
  fingerprints = import ./gpg-keys.nix;
  ownertrust = lib.concatMapStrings (fpr: "${fpr}:6:\n") fingerprints;
in
{
  home.activation.importGpgKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -r /run/agenix/gpg-secret-keys ]; then
      export GNUPGHOME=${lib.escapeShellArg gnupghome}
      $DRY_RUN_CMD install -d -m700 "$GNUPGHOME"
      missing=
      for fpr in ${lib.concatStringsSep " " fingerprints}; do
        ${gpg} --batch --list-secret-keys "$fpr" >/dev/null 2>&1 || missing=1
      done
      if [ -n "$missing" ]; then
        $DRY_RUN_CMD ${gpg} --batch --quiet --import /run/agenix/gpg-secret-keys \
          || echo "warning: importing the GPG secret keys failed"
        printf '%s' ${lib.escapeShellArg ownertrust} | $DRY_RUN_CMD ${gpg} --batch --quiet --import-ownertrust
        # At boot there is no /run/user/<uid> yet, so the daemons gpg starts
        # here put their sockets in GNUPGHOME; the session's gpg looks in the
        # runtime dir instead, starts a second keyboxd on the same database
        # and fails ("SQL library used incorrectly"). Stop them.
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpgconf --kill all
      fi
    fi
  '';
}
