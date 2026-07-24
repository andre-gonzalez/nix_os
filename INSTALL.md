# Installing `samsung-expert` (local install from USB)

This machine is **WiFi-only** (Qualcomm Atheros **QCA9377**, free in-kernel
`ath10k_pci` driver). `nixos-anywhere` does **not** work here: it must `kexec`
into a generic installer image, and that kexec drops the WiFi link (the image
has no way to rejoin the network), so the remote install stalls right after
kexec. Instead we install **locally** from a NixOS USB, where WiFi is brought
up once with `nmtui` and stays up for the whole install.

To let the machine reach the network on its **first boot**, the WiFi PSK is
stored as an `agenix` secret (`secrets/wifi-queWifi2.age`) that is decrypted at
boot using the host SSH key. That host key is pre-generated and kept in
`.extra-files/samsung-expert/etc/ssh/` (gitignored — it is the private key the
secret is encrypted to; keep it safe and never commit it). We copy it into
place manually during the install (step 5 below).

---

## 1. Build the install bundle (on your workstation)

The bundle is the whole flake **plus** the private host key, packed as a
tarball. Because it is used as a *plain-directory* flake on the target, every
file is included (the encrypted `*.age` secret too) regardless of
`.gitignore`. Run from the repo root:

```bash
cd /home/frank/projects/nix_os          # repo root
OUT="$HOME/nixos-install-bundle.tar.gz"  # where to write the tarball

STAGE="$(mktemp -d)"
cp -a . "$STAGE/nix_os"
rm -rf "$STAGE/nix_os/.git"              # plain dir => all files included, small tarball
tar czf "$OUT" -C "$STAGE" nix_os
rm -rf "$STAGE"
echo "Bundle written to: $OUT"
```

**Re-run this exact block whenever you change the config** (see
[§5](#5-rebuilding-the-bundle-after-a-config-change) for the short version) and
copy the fresh tarball to the USB stick, overwriting the old one.

Copy `$OUT` onto a spare USB stick (separate from the NixOS installer USB).

Sanity-check the bundle before copying:

```bash
tar tzf "$OUT" | grep -E 'flake.nix|secrets/wifi-queWifi2.age|extra-files/.*/ssh_host_ed25519_key$'
```

You should see the flake, the `.age` secret, and the private host key.

---

## 2. Boot the target from the NixOS **graphical** ISO

Download the *Graphical ISO image* from <https://nixos.org/download> (it ships
NetworkManager, so `nmtui` is available) and boot the target from it.

Confirm you booted in **UEFI** mode — the config uses UEFI/GRUB and a
legacy/BIOS boot will fail the bootloader install:

```bash
ls /sys/firmware/efi >/dev/null 2>&1 && echo "UEFI ✅" || echo "LEGACY ❌ — reboot the USB in UEFI mode"
```

Bring up WiFi and verify connectivity:

```bash
nmtui                 # connect to QUEWIFI-5G
ping -c3 nixos.org
```

---

## 3. Run the install (on the target)

```bash
sudo -i
export NIX_CONFIG="experimental-features = nix-command flakes"

# 1. Get the bundle off your data USB. Find it with lsblk (it is NOT /dev/sda,
#    the 894G internal disk — it's your smaller USB stick, e.g. sdb1/sdc1).
lsblk
mkdir -p /mnt/src
mount /dev/sdXY /mnt/src            # <-- replace sdXY with the bundle USB partition
cp /mnt/src/nixos-install-bundle.tar.gz /root/
umount /mnt/src
cd /root && tar xzf nixos-install-bundle.tar.gz && cd nix_os

# 2. Partition + format + mount /dev/sda  (⚠️ ERASES the entire 894G disk)
#    If this errors on an older disko CLI, use: --mode disko
nix run github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake .#samsung-expert

# 3. Generate hardware modules for THIS machine (keeps disko in charge of mounts)
nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/samsung-expert/hardware-configuration.nix

# 4. Install the system (root stays locked; the frank password is baked in)
nixos-install --flake .#samsung-expert --no-root-passwd

# 5. Inject the agenix host key BEFORE reboot, so WiFi decrypts on first boot
install -d -m700 /mnt/etc/ssh
install -m600 .extra-files/samsung-expert/etc/ssh/ssh_host_ed25519_key     /mnt/etc/ssh/ssh_host_ed25519_key
install -m644 .extra-files/samsung-expert/etc/ssh/ssh_host_ed25519_key.pub /mnt/etc/ssh/ssh_host_ed25519_key.pub

# 6. Reboot, then pull out both USB sticks so it boots from /dev/sda
reboot
```

---

## 4. After reboot

`ath10k_pci` brings up the QCA9377, `agenix` decrypts the PSK, and
`wpa_supplicant` joins `QUEWIFI-5G` automatically. Log in at the console as
`frank`, or SSH from your workstation once it is online:

```bash
ssh -i ~/.ssh/personal_id_ed25519_2023-11 frank@<ip>    # default port 22
```

Find `<ip>` from your router, or run `ip a` on the target console.

If WiFi does **not** come up on first boot, log in at the console and check:

```bash
journalctl -u wpa_supplicant
systemctl status 'run-agenix*'     # did the secret decrypt?
ls -l /run/agenix/                 # should contain wifi-queWifi2
```

The most likely culprit is the host-key copy in step 5, not the config —
`agenix` can only decrypt if `/etc/ssh/ssh_host_ed25519_key` is the exact key
the secret was encrypted to.

---

## 5. Rebuilding the bundle after a config change

Any time you edit the flake (a module, `hosts/samsung-expert/`, a secret,
etc.), rebuild the tarball and re-copy it to the USB. Optionally validate the
config first so you don't discover errors on the target:

```bash
cd /home/frank/projects/nix_os

# (optional but recommended) confirm the config still evaluates
nix eval --raw .#nixosConfigurations.samsung-expert.config.system.build.toplevel.drvPath

# rebuild the bundle
OUT="$HOME/nixos-install-bundle.tar.gz"
STAGE="$(mktemp -d)"
cp -a . "$STAGE/nix_os"
rm -rf "$STAGE/nix_os/.git"
tar czf "$OUT" -C "$STAGE" nix_os
rm -rf "$STAGE"
echo "Bundle written to: $OUT"
```

Then copy `$OUT` onto the USB stick, overwriting the previous tarball.

> **Note on secrets:** if you change WiFi networks or credentials, re-encrypt
> the secret (`secrets/wifi-queWifi2.age`) for both the host key and your
> personal key, and keep the matching private host key in
> `.extra-files/samsung-expert/`. If that host key is ever regenerated, the
> existing `.age` files can no longer be decrypted by the machine and must be
> re-encrypted to the new key.
