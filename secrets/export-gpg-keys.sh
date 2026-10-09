#!/usr/bin/env bash
# Export the GPG secret keys listed in modules/home/gpg-keys.nix ONCE and
# store that export twice, encrypted:
#   - this repo:    secrets/gpg-secret-keys.age (agenix; home/gpg.nix imports it)
#   - Ansible repo: roles/light_workstation/files/gpg-secret-keys.asc (vault;
#                   tasks/gpg.yml imports it)
#
# gpg may ask for each key's passphrase through pinentry to export it. The
# armored export only ever lives in this script's memory and in pipes; it is
# still protected by the keys' own passphrases on top of age/vault.
#
#   secrets/export-gpg-keys.sh            # write both (skips existing files)
#   FORCE=1 secrets/export-gpg-keys.sh    # replace both, e.g. after a new key
#
# ANSIBLE_REPO overrides the Ansible checkout (default below).
set -euo pipefail
umask 077

repo=$(cd "$(dirname "$0")/.." && pwd)
ansible_repo=${ANSIBLE_REPO:-$HOME/projects/system-configuration/ansible/main-ansible}
vaulted=roles/light_workstation/files/gpg-secret-keys.asc

mapfile -t fprs < <(nix eval --raw --file "$repo/modules/home/gpg-keys.nix" \
  --apply 'l: builtins.concatStringsSep "\n" l')

for fpr in "${fprs[@]}"; do
  gpg --batch --list-secret-keys "$fpr" >/dev/null 2>&1 \
    || { echo "No secret key $fpr in this keyring" >&2; exit 1; }
done

keys=$(gpg --armor --export-secret-keys "${fprs[@]}")
[[ $keys == *"BEGIN PGP PRIVATE KEY BLOCK"* ]] || { echo "Export failed" >&2; exit 1; }

# agenix (reuses the import script: recipients from secrets.nix, git add)
printf '%s\n' "$keys" | "$repo/secrets/import-from-ansible.sh" --file gpg-secret-keys /dev/stdin

# Ansible vault. ansible refuses non-blocking stdio, so stdout/stderr go to a
# log file; it holds error messages only.
if [[ -e $ansible_repo/$vaulted && -z ${FORCE:-} ]]; then
  echo "skip    $vaulted (exists; FORCE=1 to redo)"
else
  log=$(mktemp)
  if printf '%s\n' "$keys" | (cd "$ansible_repo" && ansible-vault encrypt --output "$vaulted.tmp" -) >"$log" 2>&1; then
    mv "$ansible_repo/$vaulted.tmp" "$ansible_repo/$vaulted"
    echo "ok      $vaulted"
  else
    cat "$log" >&2
    rm -f "$ansible_repo/$vaulted.tmp"
    echo "FAILED  $vaulted" >&2
    rm -f "$log"
    exit 1
  fi
  rm -f "$log"
fi
unset keys
