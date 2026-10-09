#!/usr/bin/env bash
# Re-encrypt secrets from the Ansible vault into agenix .age files.
#
# Plaintext only ever flows through pipes: ansible-vault -> age. Nothing
# secret is printed or written to disk unencrypted. Recipients come from
# secrets/secrets.nix, so that file stays the single source of truth.
#
# Usage (from anywhere):
#   secrets/import-from-ansible.sh                # import everything missing
#   FORCE=1 secrets/import-from-ansible.sh        # re-encrypt existing files too
#   secrets/import-from-ansible.sh --rekey iwd-QUEWIFI-5G
#                                                 # re-encrypt an existing .age
#                                                 # file for the recipients now
#                                                 # in secrets.nix (decrypts with
#                                                 # IDENTITY, default
#                                                 # ~/.ssh/personal_id_ed25519_2023-11)
#   printf %s 'tskey-auth-…' | secrets/import-from-ansible.sh --tailscale-stdin
#                                                 # fresh Tailscale key instead
#                                                 # of the (likely expired) one
#                                                 # in the vault
#
# ANSIBLE_REPO overrides the Ansible checkout (default below). The vault
# password comes from that repo's ansible.cfg (.vault_key).
#
# Every new .age file is `git add`-ed: a flake cannot see untracked files, and
# the modules only wire a secret once its .age file is visible.
set -euo pipefail
umask 077

repo=$(cd "$(dirname "$0")/.." && pwd)
ansible_repo=${ANSIBLE_REPO:-$HOME/projects/system-configuration/ansible/main-ansible}
files=roles/light_workstation/files
tailscale_stdin=0
[[ ${1:-} == --tailscale-stdin ]] && tailscale_stdin=1

[[ -f $ansible_repo/ansible.cfg ]] || { echo "No Ansible repo at $ansible_repo (set ANSIBLE_REPO)" >&2; exit 1; }

age=$(nix build --no-link --print-out-paths --inputs-from "$repo" nixpkgs#age)/bin/age

# agenix secret name -> file in the Ansible repo
declare -A sources=(
  [iwd-Lopes]=$files/Lopes.psk
  [iwd-LNAM5]=$files/LNAM5.psk
  [iwd-QueWiFi2]=$files/QueWiFi2.psk
  [iwd-CasaRio_5G]=$files/CasaRio_5G.psk
  [iwd-QueWifi-question]=$files/=51756520576966693f.psk
  [iwd-Davi]=$files/Davi.psk
  [ssh-personal-key]=$files/personal_id_ed25519_2023-11
  [ssh-config]=$files/config
  [rclone]=$files/rclone.conf
  [scripts-env-instapaper]=$files/instapaper
  [scripts-env-ipinfo]=$files/ipinfo
  [scripts-env-people]=$files/people
  [scripts-env-mac-address-proxmox-server]=$files/mac-address-proxmox-server
)

# ansible refuses to run unless stdin, stdout and stderr are blocking ("Ansible
# requires blocking IO"), and Claude Code's `!` prompt hands it a non-blocking
# stderr. Give it /dev/null and a regular file instead; the pipe to age on
# stdout is already blocking. Its stderr holds error messages, never plaintext,
# so it is shown on failure.
vault() {
  local log rc=0
  log=$(mktemp)
  (cd "$ansible_repo" && ansible-vault "$@" </dev/null 2>"$log") || rc=$?
  ((rc == 0)) || cat "$log" >&2
  rm -f "$log"
  return "$rc"
}

# Whole-file vaults are decrypted; anything that is not vaulted is passed as is.
plaintext() {
  local src=$1
  if head -c 14 "$ansible_repo/$src" | grep -q '^\$ANSIBLE_VAULT'; then
    vault view "$src"
  else
    cat "$ansible_repo/$src"
  fi
}

# One variable from roles/base/vars/main.yml: only its value, no trailing newline.
vault_var() {
  vault view roles/base/vars/main.yml |
    python3 -c '
import sys, yaml
var = sys.argv[1]
try:
    value = (yaml.safe_load(sys.stdin) or {}).get(var)
except yaml.YAMLError:
    sys.exit("roles/base/vars/main.yml is not plain YAML (inline !vault values?)")
if value is None or str(value).strip() == "":
    sys.exit(var + " not found in roles/base/vars/main.yml")
sys.stdout.write(str(value).strip())' "$1"
}

tailscale_key() {
  if ((tailscale_stdin)); then
    cat
  else
    vault_var tailscale_authkey
  fi
}

# Writes $name.age.tmp only; finalize() moves it into place once the whole
# pipeline (decrypt AND encrypt) has succeeded, so a failed ansible-vault can
# never leave behind an .age file holding empty input.
encrypt() {
  local name=$1 recipients
  recipients=$(nix eval --raw --file "$repo/secrets/secrets.nix" \
    --apply "x: builtins.concatStringsSep \"\n\" x.\"$name.age\".publicKeys") || return 1
  [[ -n $recipients ]] || return 1
  "$age" -R <(printf '%s\n' "$recipients") -o "$repo/secrets/$name.age.tmp"
}

finalize() {
  local name=$1
  mv "$repo/secrets/$name.age.tmp" "$repo/secrets/$name.age"
  git -C "$repo" add "secrets/$name.age"
  echo "ok      $name"
}

wanted() {
  if [[ -e $repo/secrets/$1.age && -z ${FORCE:-} ]]; then
    echo "skip    $1 (exists; FORCE=1 to redo)"
    return 1
  fi
}

if [[ ${1:-} == --rekey ]]; then
  name=${2:?usage: --rekey <secret name without .age>}
  identity=${IDENTITY:-$HOME/.ssh/personal_id_ed25519_2023-11}
  [[ -f $repo/secrets/$name.age ]] || { echo "No secrets/$name.age" >&2; exit 1; }
  if "$age" -d -i "$identity" "$repo/secrets/$name.age" | encrypt "$name"; then
    finalize "$name"
  else
    echo "FAILED  $name (rekey)" >&2
    rm -f "$repo/secrets/$name.age.tmp"
    exit 1
  fi
  exit 0
fi

failed=0
for name in "${!sources[@]}"; do
  wanted "$name" || continue
  if plaintext "${sources[$name]}" | encrypt "$name"; then
    finalize "$name"
  else
    echo "FAILED  $name (from ${sources[$name]})" >&2
    rm -f "$repo/secrets/$name.age.tmp"
    failed=1
  fi
done

if wanted ssh-port; then
  if vault_var ssh_port | encrypt ssh-port; then
    finalize ssh-port
  else
    echo "FAILED  ssh-port (from ssh_port in roles/base/vars/main.yml)" >&2
    rm -f "$repo/secrets/ssh-port.age.tmp"
    failed=1
  fi
fi

if wanted tailscale-authkey; then
  if tailscale_key | encrypt tailscale-authkey; then
    finalize tailscale-authkey
  else
    echo "FAILED  tailscale-authkey (pipe a fresh key with --tailscale-stdin)" >&2
    rm -f "$repo/secrets/tailscale-authkey.age.tmp"
    failed=1
  fi
fi

exit $failed
