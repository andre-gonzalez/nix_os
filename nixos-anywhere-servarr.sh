#!/usr/bin/env bash
# Install hosts/servarr onto the new Proxmox VM, booted from the NixOS
# installer ISO. ERASES its disk. Runbook: hosts/servarr/INSTALL.md.
#
#   TARGET=<installer's temporary LAN IP> ./nixos-anywhere-servarr.sh
#
# Needs .extra-files/servarr (the Debian host key, from
# secrets/import-from-servarr.sh): without it the VM gets a fresh host key,
# agenix decrypts nothing, and GitHub Actions' pinned known_hosts no longer
# matches.
set -euo pipefail
cd "$(dirname "$0")"

: "${TARGET:?set TARGET to the installer VM address}"
[[ -f .extra-files/servarr/etc/ssh/ssh_host_ed25519_key ]] || {
	echo "No .extra-files/servarr host key: run secrets/import-from-servarr.sh first" >&2
	exit 1
}

nix run github:nix-community/nixos-anywhere -- \
	--generate-hardware-config nixos-generate-config \
	./hosts/servarr/hardware-configuration.nix \
	--flake .#servarr \
	--extra-files ./.extra-files/servarr \
	-i ~/.ssh/personal_id_ed25519_2023-11 \
	--target-host "root@$TARGET"
