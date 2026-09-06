# T14 Gen 6 (AMD) — install runbook

Derived from `T14_PLAN.md` §11–§13. `INSTALL.md` at the repo root covers the
samsung-expert / nixos-anywhere flow; this is the local, from-ISO flow with LUKS.

⚠️ Step 2 **erases `/dev/nvme0n1`**. Everything in §1 must be done first.

---

## 1. Pre-wipe — on the running Arch install

Items 1–4 must be **committed and pushed** before the disk is erased.

1. **t14 agenix host key** — already generated into
   `.extra-files/t14/etc/ssh/ssh_host_ed25519_key{,.pub}` (gitignored).
   Copy the private half somewhere off-machine **now**; without it agenix
   cannot decrypt anything on the fresh install.

2. **`secrets/secrets.nix`** — already updated: the `workstation` placeholder is
   replaced by the real `t14` pubkey, and `t14` is a recipient of
   `iwd-QUEWIFI-5G.age` and `aws-credentials.age`.

3. **Re-encrypt every secret** to the new recipient list, then commit and push:
   ```
   cd secrets && agenix -r
   ```
   (needs `~/.ssh/personal_id_ed25519_2023-11`.)

4. **slock PAM patch** — see §2 below. Push to the fork, bump `rev` in
   `pkgs/slock/default.nix`.

5. **Back up, verified off-machine:**
   - `~/` in full, or at minimum: the dotfiles bare repo (*confirm it is
     pushed*), `~/.ssh`, `~/.gnupg`, `~/.config/autorandr`, `~/.config/dwm`,
     `~/.config/dwmblocks`, `~/.Xresources`, `~/.xinitrc`, `~/.xbindkeysrc`,
     `~/.scripts`, `~/projects`
   - `sudo tar czf iwd-backup.tar.gz -C /var/lib iwd` — root-owned, 0700, and
     the **only** copy of 15 WiFi passwords
   - `pacman -Qqe > arch-packages.txt` — reference for anything still missing

6. **Confirm the flake evaluates:**
   ```
   nix eval .#nixosConfigurations.t14.config.system.build.toplevel.drvPath
   ```

---

## 2. slock fork changes (github.com/andre-gonzalez/slock)

The fork is a *finalized* flexipatch build: zero `_PATCH` guards remain in the
446-line `slock.c`, so flipping `PAMAUTH_PATCH` in `patches.h` does nothing —
flexipatch-finalizer already stripped the PAM code. `slock.c` authenticates via
`getspnam()` + `crypt()` directly, so fingerprint unlock is **impossible as
built**. Hand-apply the patch to the flattened source:

1. Apply <https://tools.suckless.org/slock/patches/pam_auth/> to `slock.c`.
2. `config.mk`: uncomment `PAM=-lpam`.
3. `config.def.h` / `config.h`: `static const char *pam_service = "slock";`
   — the patch defaults to Arch's `"login"`; it **must** match the NixOS PAM
   service name created by `security.pam.services.slock` in `default.nix`.
4. Push, then bump `rev` in `pkgs/slock/default.nix`.

The `group = "nobody"` → `"nogroup"` fix is already handled in the Nix
derivation's `postPatch` (distro-specific, so it stays out of the fork).

---

## 3. Install

1. Boot the NixOS ISO on the T14, clone this repo.

2. **Create the initrd keyfile before disko runs** (this is the second LUKS key
   slot that gives a single passphrase prompt):
   ```
   dd if=/dev/urandom of=/tmp/crypto_keyfile.bin bs=512 count=8
   chmod 0600 /tmp/crypto_keyfile.bin
   ```
   To skip this and accept two prompts instead (GRUB, then initrd — cosmetic
   only), set `local.diskoLuks.useInitrdKeyFile = false;` in
   `hosts/t14/default.nix`. That single switch drops both halves at once — the
   extra LUKS key slot in `modules/nixos/hardware/disko-btrfs-luks.nix` and the
   `boot.initrd.secrets` / `boot.initrd.luks…keyFile` lines that consume it.

3. **Partition, format, mount** — ⚠️ erases `/dev/nvme0n1`, prompts for the new
   LUKS passphrase:
   ```
   nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#t14
   ```

4. **Place the keyfile inside encrypted /boot** (skip if step 2 was skipped):
   ```
   install -m 0600 /tmp/crypto_keyfile.bin /mnt/boot/crypto_keyfile.bin
   ```

5. **Generate hardware config**, overwriting the committed placeholder, and
   commit the result (`hosts/t14/default.nix` already imports the path):
   ```
   nixos-generate-config --no-filesystems --root /mnt
   cp /mnt/etc/nixos/hardware-configuration.nix hosts/t14/
   ```
   `--no-filesystems` keeps disko in charge of mounts.

6. **Install:**
   ```
   nixos-install --flake .#t14 --no-root-password
   ```

7. **Inject the agenix host key BEFORE reboot** — otherwise agenix cannot
   decrypt the WiFi PSK on first boot:
   ```
   install -d -m 0755 /mnt/etc/ssh
   install -m 0600 .extra-files/t14/etc/ssh/ssh_host_ed25519_key     /mnt/etc/ssh/
   install -m 0644 .extra-files/t14/etc/ssh/ssh_host_ed25519_key.pub /mnt/etc/ssh/
   ```

8. Reboot, remove the USB.

---

## 4. Post-install

1. Restore `/var/lib/iwd` from the backup (`0700 root:root`, `.psk` files `0600`).
2. Restore `~/.config/autorandr` (profiles `docked` + `laptop` + the `postswitch`
   hook) and re-clone the dotfiles bare repo.
3. `fprintd-enroll` as frank (~30 s). `/var/lib/fprint` was **not** backed up —
   re-enrolling is faster than restoring it.

### Dotfiles fixes (not blocking, see T14_PLAN.md §9/§10)

- `.xinitrc`'s commented xrandr block references `eDP-1` / `HDMI-1`. On amdgpu
  the outputs are **`eDP`** and **`HDMI-A-0`**.
- Keyboard variant disagrees in four places (`postswitch` → `dvorak-intl` +
  `caps:escape`, `.xinitrc` → `dvorak-intl` + `caps:swapescape`,
  `desktop/xorg.nix` → `dvorak` + `caps:escape`, `base/locale.nix` console →
  `dvorak`). Reconcile on `dvorak-intl`.
- Add brightness bindings to `.xbindkeysrc` (the udev rules are installed by
  `services.udev.packages = [ pkgs.brightnessctl ]`):
  ```
  "brightnessctl set +10%"
    XF86MonBrightnessUp
  "brightnessctl set 10%-"
    XF86MonBrightnessDown
  ```

---

## 5. Verification

| Check | Command / expectation |
|---|---|
| GPU | `lsmod \| grep amdgpu`; `vainfo` reports **radeonsi**; `glxinfo -B` shows Radeon 860M |
| Fingerprint | `fprintd-list frank`; `sudo -k && sudo -v` prompts for finger, Ctrl-C falls back to password |
| slock | locks and **unlocks by finger**; confirm it no longer dies on `getgrnam` |
| Boot | one passphrase prompt (or two, if the initrd keyfile was skipped) |
| Swap | `swapon --show` — zram at priority 100, `/swap/swapfile` below it |
| Power | `tlp-stat -p` shows governor `powersave` + EPP `balance_performance`/`balance_power` |
| Battery | `cat /sys/class/power_supply/BAT0/charge_control_{start,end}_threshold` → `77` / `80` |
| WiFi | `iwctl station wlan0 get-networks`; auto-connects to QUEWIFI-5G on first boot |
| Audio | `pactl list sinks short`; speakers **and** internal mic (`snd_soc_dmic`) both work |
| Suspend | close lid undocked → suspends and locks; docked → ignores lid |
| Brightness | `XF86MonBrightnessUp/Down` move `amdgpu_bl1` |
| Firmware | `fwupdmgr get-devices` lists UEFI + fingerprint sensor |
| Dock | HDMI hotplug flips autorandr `laptop` ↔ `docked` |

Once slock unlocks by finger, `security.wrappers.slock` in
`modules/nixos/desktop/xorg.nix` may be removable — PAM delegates shadow reads
to the setuid `unix_chkpwd` helper. Verify first, remove in a follow-up.

---

## 6. Remote install onto a test machine (`nixos-anywhere`)

Installs the T14 config onto *someone else's* box over ssh, disk encryption
included. Uses the `.#t14-remote` flake output (`hosts/t14/remote-install.nix`),
which differs from `.#t14` in four ways only — passphrase from a file, no initrd
keyfile, no agenix, its own hardware scan. The reasoning for each is in the
header of that file. Hostname becomes `t14-test`.

⚠️ This **erases the target's disk**. It is also, unavoidably, *your* config:
your user, your hashed password, your authorized ssh keys.

### 6.1 On the target (booted from the NixOS ISO)

nixos-anywhere logs in as **root**, but the graphical ISO gives you `nixos`, and
sshd there is `prohibit-password` — so install your public key for root:

```bash
sudo install -d -m700 /root/.ssh
sudo cp ~/.ssh/authorized_keys /root/.ssh/authorized_keys   # if you already keyed in as nixos
# ...or paste it directly:
sudo tee /root/.ssh/authorized_keys < /dev/stdin            # then paste, Ctrl-D
```

Note the disk to erase, and confirm UEFI (the config is UEFI/GRUB only; a
legacy boot fails at bootloader install):

```bash
lsblk -dno NAME,SIZE,MODEL
ls /sys/firmware/efi >/dev/null 2>&1 && echo "UEFI ✅" || echo "LEGACY ❌"
```

### 6.2 On this machine

1. Confirm `disko.devices.disk.main.device` in
   `hosts/t14/remote-install.nix` matches the target's disk, and that the rest
   of that file's hardware assumptions still hold — see §6.4.

2. Write the LUKS passphrase to a local file — it is read by disko on the
   installer and never copied to the target:

   ```bash
   (umask 077; printf '%s' 'the-passphrase' > /tmp/luks.key)
   ```

3. Check that both host outputs still evaluate:

   ```bash
   nix eval --raw .#nixosConfigurations.t14-remote.config.system.build.toplevel.drvPath
   ```

4. Install:

   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --generate-hardware-config nixos-generate-config \
       ./hosts/t14/hardware-configuration.remote.nix \
     --flake .#t14-remote \
     --disk-encryption-keys /tmp/luks.key /tmp/luks.key \
     -i ~/.ssh/personal_id_ed25519_2023-11 \
     --target-host root@<target-ip>
   ```

   The two `--disk-encryption-keys` arguments are *remote path* then *local
   path*; the remote one must match `local.diskoLuks.passwordFile`.

   `./nixos-anywhere-t14.sh` at the repo root wraps this. It also exports a
   GitHub token from `gh auth token` into `NIX_CONFIG`: flake inputs are fetched
   through `api.github.com`, which allows only 60 requests an hour
   unauthenticated, and running out shows up as a bare `HTTP error 403` on
   `github:nix-community/nixos-anywhere`. `curl -s https://api.github.com/rate_limit`
   confirms it (`core.remaining`). Without `gh`, either wait for the reset or use
   `git+https://github.com/nix-community/nixos-anywhere`, which clones over git
   and skips the API.

   nixos-anywhere kexecs into its own installer, so the target's ISO desktop
   dies a minute in — that is expected. It needs a **wired** link: kexec drops
   WiFi, which is exactly why `samsung-expert` is installed locally instead
   (see the root `INSTALL.md`).

### 6.3 After it reboots

- **Two passphrase prompts** at boot — GRUB, then the initrd. Expected here; the
  single-prompt keyfile is only used by the local install of the real T14.
- No WiFi profile is seeded (no agenix). Log in as `frank` and use
  `iwctl station wlan0 connect <ssid>`.
- Commit the generated `hosts/t14/hardware-configuration.remote.nix` if the
  target is going to stick around and rebuild itself from this repo — reverting
  it to the placeholder costs that machine its real scan (`kvm-intel`, its
  microcode default, its actual initrd modules). Revert it only when the machine
  is done with:

  ```bash
  git checkout hosts/t14/hardware-configuration.remote.nix hosts/t14/remote-install.nix
  ```

- To let the target maintain itself, clone this repo on it and rebuild there.
  `andre-gonzalez/nix_os` is public, so no key is needed:

  ```bash
  git clone https://github.com/andre-gonzalez/nix_os.git ~/nix_os
  cd ~/nix_os && sudo nixos-rebuild switch --flake .#t14-remote
  ```

  Note `.#t14-remote`, not `./nix_os#t14-remote`, when you are already inside the
  clone — the flake path is resolved relative to the current directory.

### 6.4 Retargeting at other hardware

`hosts/t14/remote-install.nix` is currently pinned to one machine — an Intel
i7-8750H laptop with a GTX 1060 Mobile — and carries the module surgery that
needs: `disabledModules` drops `amd.nix` / `power-amd.nix` /
`power-thinkpad.nix`, `intel.nix` + `power-intel.nix` come in instead, and the
`nixos-hardware` list in `flake.nix` swaps the AMD/ThinkPad modules for
`common-pc-laptop`, `common-cpu-intel`, `common-gpu-nvidia-disable`,
`common-pc-ssd`. Its file header records the target.

Two traps worth remembering when the next machine differs:

- `hardware/amd.nix` and `hardware/intel.nix` both define
  `environment.variables.LIBVA_DRIVER_NAME` and `VDPAU_DRIVER`, so they cannot
  coexist — the wrong one must be *disabled*, not overridden.
- `hardware/nvidia.nix` sets `hardware.nvidia.open = true`, which needs Turing
  or newer. The GTX 1060 is Pascal, so that module is deliberately not imported;
  the dGPU is blacklisted and unbound instead (no CUDA, no Optimus offload — an
  acceptable trade on a test box, but if you want the card, import `nvidia.nix`
  with `open = lib.mkForce false` and add `hardware.nvidia.prime` bus IDs).
