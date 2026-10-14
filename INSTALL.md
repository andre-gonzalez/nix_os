# Installing `samsung-expert`

This machine is **WiFi-only** (Qualcomm Atheros **QCA9377**, free in-kernel
`ath10k_pci` driver). A plain `nixos-anywhere` run does **not** work here: by
default it `kexec`s into its own installer image, and that drops the WiFi link
(the image cannot rejoin the network), so the install stalls right after kexec.

The fix is to skip the kexec phase. You boot the NixOS ISO on the target
yourself, connect WiFi once with `nmtui`, and `nixos-anywhere` installs from
your workstation over that connection (`--phases disko,install,reboot`).
`./nixos-anywhere.sh` at the repo root does all of it.

The disk is **encrypted** (LUKS2 + btrfs, swapfile inside —
`modules/nixos/hardware/disko-btrfs-luks.nix`, same layout as t14). `/boot` is
the unencrypted ESP, as on Arch, and the initrd asks for the passphrase once,
with the **Dvorak** keymap.

⚠️ Installing erases the whole disk. Back up `/home/frank` (and anything else
you want to keep) before you start.

To let the machine reach the network on its **first boot**, the WiFi PSKs are
stored as `agenix` secrets (`secrets/iwd-*.age`) that are decrypted at boot
using the host SSH key. That host key is pre-generated and kept in
`.extra-files/samsung-expert/etc/ssh/` (gitignored — it is the private key the
secrets are encrypted to; keep it safe and never commit it). The script copies
it into place with `--extra-files`.

---

## 1. Remote install from your workstation (recommended)

### 1.1 On the target

1. Boot the NixOS **graphical** ISO from <https://nixos.org/download> in
   **UEFI** mode. The config uses UEFI/GRUB; a legacy boot fails at the
   bootloader install. Check with:

   ```bash
   ls /sys/firmware/efi >/dev/null 2>&1 && echo "UEFI ✅" || echo "LEGACY ❌"
   ```

2. Connect WiFi:

   ```bash
   nmtui                 # connect to QUEWIFI-5G
   ping -c3 nixos.org
   ```

3. Let the workstation log in, and find the address:

   ```bash
   passwd                       # password for the `nixos` user, used once
   sudo systemctl start sshd
   ip a                         # note the WiFi IP
   ```

### 1.2 On your workstation

Run from the repo root:

```bash
./nixos-anywhere.sh <target-ip>
```

The script:

1. Copies `~/.ssh/personal_id_ed25519_2023-11.pub` to the `nixos` user (asks
   for the password from step 1.1.3 once), then to root. The ISO's sshd refuses
   root passwords, so root only gets the key.
2. Shows the target's disks and the one it will erase (`/dev/sda`), and stops
   until you type `yes`. Device names can move when USB sticks are attached:
   make sure `/dev/sda` is the **894G** internal disk. If it is not, abort and
   set `disko.devices.disk.main.device` in `hosts/samsung-expert/default.nix`.
3. Asks for the new LUKS passphrase (twice) and writes it to `/tmp/luks.key`,
   which `--disk-encryption-keys` ships to the installer's tmpfs. It is never
   copied to the installed system, and the script deletes the local copy at
   the end.
4. Runs `nixos-anywhere`: partitions/encrypts/formats with disko, regenerates
   `hosts/samsung-expert/hardware-configuration.nix` for this machine, installs
   the system, copies the agenix host key, and reboots.

The flake inputs are fetched through `api.github.com`, which allows only 60
requests an hour unauthenticated. If `gh` is logged in, the script passes its
token to Nix through `NIX_CONFIG`.

The passphrase prompt at boot uses **Dvorak**: type the same *characters* you
entered in the script.

Afterwards, commit the regenerated `hosts/samsung-expert/hardware-configuration.nix`.

---

## 2. After reboot

Remove the USB stick when the target reboots. The initrd asks for the LUKS
passphrase (Dvorak), then the machine boots straight into the desktop (tty1
autologin). `ath10k_pci` brings up the QCA9377, `agenix` decrypts the PSKs into
`/var/lib/iwd`, and `iwd` joins a known network automatically. Log in at the
console as `frank`, or SSH from your workstation once it is online:

```bash
ssh samsung-expert      # ~/.ssh/config: port from secrets/ssh-port.age, key auth only
```

Find the IP from your router, or run `ip a` on the target console, and update
`Hostname` in `~/.ssh/config` if it changed. SSH is accepted only from
`192.168.0.0/16` and Tailscale.

If WiFi does **not** come up on first boot, log in at the console and check:

```bash
journalctl -u iwd
journalctl -b | grep -i agenix     # did the secrets decrypt?
ls -l /var/lib/iwd/                # should contain QUEWIFI-5G.psk and the others
```

The most likely culprit is the host key, not the config — `agenix` can only
decrypt if `/etc/ssh/ssh_host_ed25519_key` is the exact key the secrets were
encrypted to.

---

## 3. Updating an installed system

Once the machine runs this flake, push changes without reinstalling. From the
published `main`:

```bash
ssh -t samsung-expert sudo nixos-rebuild switch --refresh --flake github:andre-gonzalez/nix_os#samsung-expert
```

From the local checkout (unpushed changes too). `--build-host` makes the target
build: `frank` is not a Nix trusted user there, so it refuses store paths built
on the workstation.

```bash
NIX_SSHOPTS="-t" nix run nixpkgs#nixos-rebuild -- switch --flake .#samsung-expert \
  --target-host samsung-expert --build-host samsung-expert --sudo --ask-sudo-password
```

Do **not** do this on a stock NixOS install (from the graphical installer): its
disk layout and host key differ from this config, so it will not boot. Install
with §1 instead.

---

## 4. Fallback: local install from a USB bundle

Use this only if the remote install cannot work (for example, no workstation on
the same network). Everything runs on the target.

### 4.1 Build the bundle (on your workstation)

The bundle is the whole flake **plus** the private host key, packed as a
tarball. Because it is used as a *plain-directory* flake on the target, every
file is included regardless of `.gitignore`. Run from the repo root:

```bash
nix eval --raw .#nixosConfigurations.samsung-expert.config.system.build.toplevel.drvPath  # optional check

OUT="$HOME/nixos-install-bundle.tar.gz"
STAGE="$(mktemp -d)"
cp -a . "$STAGE/nix_os"
rm -rf "$STAGE/nix_os/.git"              # plain dir => all files included, small tarball
tar czf "$OUT" -C "$STAGE" nix_os
rm -rf "$STAGE"
tar tzf "$OUT" | grep -E 'flake.nix|secrets/iwd-QUEWIFI-5G.age|extra-files/.*/ssh_host_ed25519_key$'
```

Copy `$OUT` onto a spare USB stick (separate from the NixOS installer USB).
Re-run this block whenever you change the config.

### 4.2 Install (on the target, booted from the ISO, WiFi up with `nmtui`)

```bash
sudo -i
export NIX_CONFIG="experimental-features = nix-command flakes"

# 1. Get the bundle off your data USB (NOT /dev/sda — find it with lsblk).
lsblk
mkdir -p /mnt/src
mount /dev/sdXY /mnt/src            # <-- replace sdXY with the bundle USB partition
cp /mnt/src/nixos-install-bundle.tar.gz /root/
umount /mnt/src
cd /root && tar xzf nixos-install-bundle.tar.gz && cd nix_os

# 2. Write the LUKS passphrase where disko expects it
#    (local.diskoLuks.passwordFile). printf, not echo: no trailing newline.
#    Type the same characters you will type on the Dvorak initrd prompt.
(umask 077; printf '%s' 'the-passphrase' > /tmp/luks.key)

# 3. Partition + encrypt + format + mount /dev/sda  (⚠️ ERASES the entire 894G disk)
nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake .#samsung-expert
rm /tmp/luks.key

# 4. Generate hardware modules for THIS machine (keeps disko in charge of mounts)
nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/samsung-expert/hardware-configuration.nix

# 5. Install the system (root stays locked; the frank password is baked in)
nixos-install --flake .#samsung-expert --no-root-passwd

# 6. Inject the agenix host key BEFORE reboot, so the secrets decrypt on first boot
install -d -m700 /mnt/etc/ssh
install -m600 .extra-files/samsung-expert/etc/ssh/ssh_host_ed25519_key     /mnt/etc/ssh/ssh_host_ed25519_key
install -m644 .extra-files/samsung-expert/etc/ssh/ssh_host_ed25519_key.pub /mnt/etc/ssh/ssh_host_ed25519_key.pub

# 7. Reboot, then pull out both USB sticks so it boots from /dev/sda
reboot
```

Then continue with §2.

---

> **Note on secrets:** if you change WiFi networks or credentials, re-encrypt
> the matching `secrets/iwd-*.age` for both the host key and your personal key,
> and keep the matching private host key in `.extra-files/samsung-expert/`. If
> that host key is ever regenerated, the existing `.age` files can no longer be
> decrypted by the machine and must be re-encrypted to the new key.
