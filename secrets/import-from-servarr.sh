#!/usr/bin/env bash
# Copy the servarr server's secrets from the running Debian host into agenix,
# plus its SSH host key into .extra-files for nixos-anywhere. Run once, from
# the laptop, before installing hosts/servarr (see hosts/servarr/INSTALL.md).
#
#   secret                      from (Debian)                          used by
#   servarr-env                 /opt/servarr/.env                      deploy.nix
#   servarr-github-read         /var/lib/deploy/.ssh/github_read       deploy.nix
#   servarr-radicale-deploy     ~frank/.ssh/radicale_deploy            radicale-push.nix
#   servarr-totp                ~frank/.google_authenticator           ssh-totp.nix
#   hosts/servarr/ci-deploy-key.pub   the CI key in deploy's authorized_keys (public)
#   .extra-files/servarr/etc/ssh/ssh_host_ed25519_key{,.pub}   (never committed)
#
# Plaintext only flows through pipes into age, except the host key, which
# nixos-anywhere needs as a file (.extra-files/ is gitignored). The root-only
# files are copied once, with one sudo, into a 0700 directory in frank's home
# on the server, and removed again on exit.
#
# Asks for: one TOTP code (ssh), frank's sudo password on the server.
#
# Usage:  secrets/import-from-servarr.sh            # import what is missing
#         FORCE=1 secrets/import-from-servarr.sh    # re-import everything
# SERVARR_HOST overrides the ssh destination (default: servarr).
set -euo pipefail
umask 077

repo=$(cd "$(dirname "$0")/.." && pwd)
host=${SERVARR_HOST:-servarr}
age=$(nix build --no-link --print-out-paths --inputs-from "$repo" nixpkgs#age)/bin/age
# Relative paths below are in frank's home: remote commands start there.
stage=.import-servarr

# One connection, one TOTP code, for every command below.
cm=${XDG_RUNTIME_DIR:-/tmp}/import-servarr.$$
ssh -o ControlMaster=yes -o ControlPath="$cm" -o ControlPersist=10m -fN "$host"
remote() { ssh -o ControlPath="$cm" "$host" "$@"; }
remote_tty() { ssh -t -o ControlPath="$cm" "$host" "$@"; } # for the sudo prompt
# shellcheck disable=SC2329 # run by the EXIT trap
cleanup() {
	remote "rm -rf $stage" || true
	ssh -o ControlPath="$cm" -O exit "$host" 2>/dev/null || true
}
trap cleanup EXIT

remote_tty "sudo install -d -m 700 -o frank $stage && sudo install -m 600 -o frank -t $stage \
  /opt/servarr/.env \
  /var/lib/deploy/.ssh/github_read \
  /var/lib/deploy/.ssh/authorized_keys \
  /etc/ssh/ssh_host_ed25519_key \
  /etc/ssh/ssh_host_ed25519_key.pub"

encrypt() {
	local name=$1 recipients
	recipients=$(nix eval --raw --file "$repo/secrets/secrets.nix" \
		--apply "x: builtins.concatStringsSep \"\n\" x.\"$name.age\".publicKeys") || return 1
	[[ -n $recipients ]] || return 1
	"$age" -R <(printf '%s\n' "$recipients") -o "$repo/secrets/$name.age.tmp"
}

failed=0
import() {
	local name=$1 path=$2
	if [[ -e $repo/secrets/$name.age && -z ${FORCE:-} ]]; then
		echo "skip    $name (exists; FORCE=1 to redo)"
		return
	fi
	# `cat` fails on a missing file, and pipefail carries that through encrypt.
	if remote "cat $path" | encrypt "$name"; then
		mv "$repo/secrets/$name.age.tmp" "$repo/secrets/$name.age"
		git -C "$repo" add "secrets/$name.age"
		echo "ok      $name"
	else
		echo "FAILED  $name (from $path)" >&2
		rm -f "$repo/secrets/$name.age.tmp"
		failed=1
	fi
}

import servarr-env "$stage/.env"
import servarr-github-read "$stage/github_read"
import servarr-radicale-deploy .ssh/radicale_deploy
import servarr-totp .google_authenticator

# Host key: must be the one secrets/secrets.nix encrypts the servarr secrets
# to, or agenix on the new host decrypts nothing.
keys=$repo/.extra-files/servarr/etc/ssh
install -d -m 755 "$repo/.extra-files/servarr/etc" && install -d -m 755 "$keys"
remote "cat $stage/ssh_host_ed25519_key" >"$keys/ssh_host_ed25519_key"
remote "cat $stage/ssh_host_ed25519_key.pub" >"$keys/ssh_host_ed25519_key.pub"
chmod 600 "$keys/ssh_host_ed25519_key"
chmod 644 "$keys/ssh_host_ed25519_key.pub"
want=$(nix eval --raw --file "$repo/secrets/secrets.nix" \
	--apply 'x: builtins.head x."servarr-env.age".publicKeys')
if [[ $(cut -d' ' -f1,2 "$keys/ssh_host_ed25519_key.pub") == "$(cut -d' ' -f1,2 <<<"$want")" ]]; then
	echo "ok      host key -> .extra-files/servarr (matches secrets.nix)"
else
	echo "FAILED  host key does not match the servarr key in secrets/secrets.nix" >&2
	failed=1
fi

# The CI login key: public, tracked. Only the key and its comment, without
# Debian's restrict/from=/command= options (deploy.nix adds its own).
ci=$(remote "cat $stage/authorized_keys" | grep -oE 'ssh-ed25519 [A-Za-z0-9+/=]+( [^ ]+)?$' | head -1 || true)
if [[ -n $ci ]]; then
	printf '%s\n' "$ci" >"$repo/hosts/servarr/ci-deploy-key.pub"
	git -C "$repo" add hosts/servarr/ci-deploy-key.pub
	echo "ok      hosts/servarr/ci-deploy-key.pub"
else
	echo "FAILED  no ssh-ed25519 key in deploy's authorized_keys" >&2
	failed=1
fi

exit $failed
