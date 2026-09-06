#!/usr/bin/env bash
# Remote install of .#t14-remote onto a test machine. See hosts/t14/INSTALL.md §6.
# ⚠️ ERASES the target's disk (the one named in hosts/t14/remote-install.nix).
set -euo pipefail

TARGET="root@192.168.10.215"   # Intel i7-8750H test box; erases its /dev/sda
KEYFILE="/tmp/luks.key"   # LUKS passphrase; must match local.diskoLuks.passwordFile

# Flake inputs are fetched through api.github.com, which allows 60 requests an
# hour unauthenticated — enough to fail mid-install with a bare HTTP 403. Nix
# reads a token from the access-tokens setting; take it from the gh login rather
# than storing one in the repo. NIX_CONFIG keeps it out of the process argv.
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  export NIX_CONFIG="access-tokens = github.com=$(gh auth token)"
else
  echo "warning: no gh login; falling back to unauthenticated GitHub API" >&2
fi

# Prompt rather than take the passphrase as an argument or an env var: this is
# the disk passphrase, and it should not end up in shell history or in ps output.
# printf '%s' — NOT echo — because a trailing newline becomes part of the key
# material, and you would then have to type that newline at every boot prompt.
if [[ ! -f "$KEYFILE" ]]; then
  read -rsp "LUKS passphrase for the new install: " pass1; echo
  read -rsp "Repeat: " pass2; echo
  [[ -n "$pass1" ]]           || { echo "error: empty passphrase" >&2; exit 1; }
  [[ "$pass1" == "$pass2" ]]  || { echo "error: passphrases differ" >&2; exit 1; }
  ( umask 077; printf '%s' "$pass1" > "$KEYFILE" )
  unset pass1 pass2
  echo "wrote $KEYFILE ($(stat -c '%a %s bytes' "$KEYFILE"))"
fi

nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config \
    ./hosts/t14/hardware-configuration.remote.nix \
  --flake .#t14-remote \
  --disk-encryption-keys "$KEYFILE" "$KEYFILE" \
  -i ~/.ssh/personal_id_ed25519_2023-11 \
  --target-host "$TARGET"
