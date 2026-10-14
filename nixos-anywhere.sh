#!/usr/bin/env bash
# Remote install of .#samsung-expert from this machine.
# ⚠️ ERASES the target's /dev/sda (disko-btrfs-luks.nix).
#
# On the target, first:
#   1. Boot the NixOS ISO (UEFI) and connect WiFi with `nmtui`.
#   2. `passwd` (for the `nixos` user) and `sudo systemctl start sshd`.
#   3. `ip a` for the address.
# Then here:  ./nixos-anywhere.sh <ip>
#
# The kexec phase is skipped: kexec into nixos-anywhere's own image drops the
# WiFi link (this machine has no ethernet). The booted ISO keeps the
# NetworkManager connection for the whole install.
set -euo pipefail

IP="${1:?usage: $0 <target-ip>}"
TARGET="root@$IP"
SSH_KEY="$HOME/.ssh/personal_id_ed25519_2023-11"
KEYFILE="/tmp/luks.key" # must match local.diskoLuks.passwordFile
DISK="/dev/sda"         # must match disko.devices.disk.main.device

# nixos-anywhere logs in as root, but the ISO's sshd refuses root passwords
# (prohibit-password). Key the `nixos` user (asks for its password once), then
# hand the same key to root through nixos's passwordless sudo.
ssh-copy-id -i "$SSH_KEY.pub" -o StrictHostKeyChecking=no "nixos@$IP"
ssh -i "$SSH_KEY" "nixos@$IP" \
	'sudo install -d -m700 /root/.ssh && sudo install -m600 ~/.ssh/authorized_keys /root/.ssh/authorized_keys'

# Device names can move when the USB sticks are attached. Show what is about
# to be erased and make the user confirm it.
ssh -i "$SSH_KEY" "$TARGET" lsblk -o NAME,SIZE,MODEL,TRAN
echo
ssh -i "$SSH_KEY" "$TARGET" lsblk -dno NAME,SIZE,MODEL "$DISK"
read -rp "ERASE the disk above ($DISK)? Type 'yes': " answer
[[ $answer == "yes" ]] || {
	echo "aborted" >&2
	exit 1
}

# Flake inputs are fetched through api.github.com, which allows 60 requests an
# hour unauthenticated. NIX_CONFIG keeps the token out of the process argv.
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
	export NIX_CONFIG="access-tokens = github.com=$(gh auth token)"
else
	echo "warning: no gh login; falling back to unauthenticated GitHub API" >&2
fi

# printf '%s', not echo: a trailing newline would become part of the key.
# The initrd prompt uses Dvorak; type the same characters there.
if [[ ! -f $KEYFILE ]]; then
	read -rsp "LUKS passphrase for the new install: " pass1
	echo
	read -rsp "Repeat: " pass2
	echo
	[[ -n $pass1 ]] || {
		echo "error: empty passphrase" >&2
		exit 1
	}
	[[ $pass1 == "$pass2" ]] || {
		echo "error: passphrases differ" >&2
		exit 1
	}
	(
		umask 077
		printf '%s' "$pass1" >"$KEYFILE"
	)
	unset pass1 pass2
fi
trap 'rm -f "$KEYFILE"' EXIT

nix run github:nix-community/nixos-anywhere -- \
	--phases disko,install,reboot \
	--generate-hardware-config nixos-generate-config \
	./hosts/samsung-expert/hardware-configuration.nix \
	--flake .#samsung-expert \
	--disk-encryption-keys "$KEYFILE" "$KEYFILE" \
	--extra-files ./.extra-files/samsung-expert \
	-i "$SSH_KEY" \
	--target-host "$TARGET"
