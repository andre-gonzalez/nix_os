# GPG secret keys — imported from the agenix secret "gpg-secret-keys" (an
# armored `gpg --export-secret-keys` made by secrets/export-gpg-keys.sh) when
# any of them is missing, then trusted ultimately, as on Arch. The keys stay
# protected by their own passphrases inside the export, so importing needs no
# passphrase; using them asks through the agent's pinentry
# (nixos/desktop/gnupg.nix).
{ lib, pkgs, ... }:
let
  gpg = "${pkgs.gnupg}/bin/gpg";
  fingerprints = import ./gpg-keys.nix;
  ownertrust = lib.concatMapStrings (fpr: "${fpr}:6:\n") fingerprints;
in
{
  home.activation.importGpgKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -r /run/agenix/gpg-secret-keys ]; then
      missing=
      for fpr in ${lib.concatStringsSep " " fingerprints}; do
        ${gpg} --batch --list-secret-keys "$fpr" >/dev/null 2>&1 || missing=1
      done
      if [ -n "$missing" ]; then
        $DRY_RUN_CMD ${gpg} --batch --quiet --import /run/agenix/gpg-secret-keys \
          || echo "warning: importing the GPG secret keys failed"
        printf '%s' ${lib.escapeShellArg ownertrust} | $DRY_RUN_CMD ${gpg} --batch --quiet --import-ownertrust
      fi
    fi
  '';
}
