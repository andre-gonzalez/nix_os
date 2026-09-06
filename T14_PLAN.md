# ThinkPad T14 Gen 6 (AMD) — NixOS plan

Implemented. Kept for the reasoning behind each decision; the runbook now lives
in `hosts/t14/INSTALL.md`.

Two sections were overtaken by work that landed on `main` first and were
implemented differently:

* **§6 (power)** — `main` split TLP into `power.nix` (shared) +
  `power-amd.nix` / `power-intel.nix` / `power-thinkpad.nix`. t14 imports that
  trio instead of the single AMD module this plan describes. Same conclusions
  about the `powersave` governor under amd-pstate-epp; charge thresholds are
  77/80 rather than 75/80.
* **§14.1 (dwm packaged twice)** — already consolidated to a single
  `pkgs/dwm/default.nix` on `main`.

---

## 1. Verified machine facts

Everything below was read off the running Arch install, not assumed.

| Thing | Value | Consequence |
|---|---|---|
| Model | `21QJCTO1WW` — ThinkPad T14 Gen 6, BIOS `R2XET39W (1.19)` | Lenovo firmware, no Samsung-style NVRAM quirks |
| CPU | **AMD Ryzen AI 7 PRO 350** (Krackan Point) | `hardware/intel.nix` is wrong for this host and must not be imported |
| GPU | Radeon 860M `[1002:1114]`, `amdgpu` | mesa/radeonsi, not `iHD` |
| Backlight | `amdgpu_bl1` | native GPU backlight already works |
| CPU scaling | `amd-pstate-epp`, EPP currently `performance` | governor must stay `powersave`; see §6 |
| Fingerprint | **Synaptics `06cb:00f9`**, press-type; enrolled + working on Arch | ✅ `0x00F9` **is** in the PID table of nixpkgs libfprint 1.94.10 |
| WiFi | MediaTek **MT7925** (`mt7925e`) | needs `linux-firmware`; iwd already in use |
| Bluetooth | MediaTek `0e8d:e025` via `btusb` | existing `desktop/bluetooth.nix` is enough |
| Audio | SOF **AMD ACP7.0** + `nau8821` codec + `snd_soc_dmic` | needs `sof-firmware` |
| Sleep | `mem_sleep = [s2idle]` — **no S3** | closed lid still draws power |
| Panel | eDP **1920x1200 @60** | no HiDPI work needed |
| External | `HDMI-A-0` @ 2560x1080 (ultrawide, docked) | output names are `eDP` / `HDMI-A-0`, **not** `eDP-1` / `HDMI-1` |
| Battery | 57 Wh, **9 cycles** | brand new — charge thresholds are worth it now, not later |
| Platform profile | `low-power / balanced / performance` (amd_pmf) | TLP can drive it |
| TPM | `tpm0` present; Secure Boot **disabled** | unused under the chosen GRUB design |
| NPU | `amdxdna` `[1022:17f0]` loaded | out of scope, no userspace configured |
| Disk | 238 GB WD SN7100, currently LUKS+btrfs, zram-only swap | to be wiped |
| RAM | ~27 GiB usable | 8 G swapfile, no hibernation |

`hardware.enableRedistributableFirmware = true` pulls **both `linux-firmware` and `sof-firmware`** in the
pinned nixpkgs (verified in `nixos/modules/hardware/all-firmware.nix`). It is currently set only in the
samsung host file — the T14 host **must** set it or amdgpu will not initialize.

---

## 2. Decisions

| # | Decision | Chosen |
|---|---|---|
| 1 | Host identity | T14 **replaces `workstation`**; rename to **`t14`** |
| 2 | Install | Wipe + disko, **with LUKS added** |
| 3 | Boot | **GRUB**, `/boot` **inside** LUKS, ESP at `/boot/efi` |
| 4 | Swap | **8 G btrfs swapfile inside LUKS** + zram, **no hibernation** |
| 5 | Fingerprint | **sudo + slock**, patching the slock fork |
| 6 | slock changes | **Split**: PAM patch upstream in the fork, `nogroup` fix in the Nix derivation |
| 7 | Hardware modules | **Compose nixos-hardware common modules** |
| 8 | Kernel | **`linuxPackages_latest`** (7.1.3) |
| 9 | Power | **TLP rewritten for AMD** + 75/80 charge thresholds |
| 10 | WiFi | **iwd**; restore `/var/lib/iwd` + agenix-seed home PSK |
| 11 | Displays | autorandr profiles **stay in the dotfiles bare repo** |
| 12 | Roles | docker + btrfs/snapper + tailscale + libvirt/windows-vm; **drop preload** |
| 13 | Laptop bits | lock-on-suspend, brightness Fn keys, fwupd |

---

## 3. Host rename and flake wiring

- `git mv hosts/workstation hosts/t14`
- `networking.hostName = "t14"`
- `flake.nix`: rename `nixosConfigurations.workstation` → `t14`; add the nixos-hardware modules
  (the input is declared today but **never used** — its only reference is a commented-out line).

```nix
t14 = nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs customPkgs; };
  modules = [
    ./hosts/t14/default.nix
    nixos-hardware.nixosModules.lenovo-thinkpad          # trackpoint + emulateWheel, pulls common/pc/laptop
    nixos-hardware.nixosModules.common-cpu-amd-pstate    # amd_pstate=active
    nixos-hardware.nixosModules.common-gpu-amd           # modesetting, graphics.enable32Bit, amdgpu.initrd
    nixos-hardware.nixosModules.common-pc-ssd            # fstrim
    home-manager.nixosModules.home-manager
    agenix.nixosModules.default
    disko.nixosModules.disko
  ];
};
```

**Deliberately not** `lenovo-thinkpad-t14-amd-gen5`: there is no `t14-amd-gen6` upstream, and gen5
hardcodes `acpi.ec_no_wakeup=1` for a Gen 5 EC bug. Once imported, a single kernel param cannot be
removed without `mkForce`-ing the whole list.

`hosts/t14/default.nix` imports: `base`, `desktop`, `hardware/btrfs.nix`, `hardware/amd.nix` (new),
`hardware/power-amd.nix` (new), `hardware/disko-btrfs-luks.nix` (new), `services/tailscale.nix`,
`services/docker.nix`, `virtualization/libvirt.nix`, `virtualization/windows-vm.nix`.

**Not** `services/snapper.nix` — it is a thin re-export of `hardware/btrfs.nix`, and `workstation`
currently imports both (already logged as item 4 in `NIXOS_STRUCTURE.md`). **Not** `services/preload.nix`.
**Not** `hardware/intel.nix` or `hardware/nvidia.nix`.

---

## 4. Disk: `modules/nixos/hardware/disko-btrfs-luks.nix` (new)

Keep the existing unencrypted `disko-btrfs.nix` for other hosts; write a separate encrypted variant.

Layout on `/dev/nvme0n1`:

```
ESP     512M  vfat  → /boot/efi        (GRUB EFI binary only; kernels live inside LUKS)
luks    100%  → btrfs
                @      → /       compress=zstd,noatime
                @home  → /home   compress=zstd,noatime
                @nix   → /nix    compress=zstd,noatime
                @swap  → /swap   swapfile 8G (btrfs filesystem mkswapfile — NOCOW, no compression)
```

Key points:

- **The current `disko-btrfs.nix` has a real security bug for this design**: a *plaintext* swap partition
  with `resumeDevice = true`. Under LUKS that leaks RAM contents to disk in the clear. The new module has
  no swap partition at all — swap is a file *inside* the encrypted container.
- `disko.devices.disk.main.device = "/dev/nvme0n1"` (the shared module defaults to `/dev/sda`).
- LUKS must be formatted for GRUB: **GRUB 2.12 in your pinned nixpkgs carries no argon2 patch** (verified
  against its patch list — it does carry the TPM2 key-protector series, unused here). So:
  `extraFormatArgs = [ "--pbkdf" "pbkdf2" ]`. Without this GRUB cannot open the container.
- Verified disko option names: `passwordFile`, `askPassword`, `settings.keyFile`, `additionalKeyFiles`,
  `extraFormatArgs`, `extraOpenArgs`, `initrdUnlock`.
- Swap: disko's btrfs type supports `swap.<name>.size` and runs `btrfs filesystem mkswapfile`.
- `zramSwap.enable = true; zramSwap.memoryPercent = 25; zramSwap.priority = 100;` so zram is preferred
  over the disk swapfile (matches the 4 G zram you run on Arch today, scaled to RAM).
- No `boot.resumeDevice`, no `resume_offset`, no `hibernate` — by decision.

Bootloader in `hosts/t14/default.nix`:

```nix
boot.loader.grub = {
  enable = true;
  device = "nodev";
  efiSupport = true;
  enableCryptodisk = true;      # verified option; exports GRUB_ENABLE_CRYPTODISK=y
  useOSProber = false;
  default = "saved";
  timeout = 1;
};
boot.loader.efi.canTouchEfiVariables = true;   # Lenovo firmware is fine with NVRAM entries,
boot.loader.efi.efiSysMountPoint = "/boot/efi"; # unlike the Samsung (efiInstallAsRemovable)
boot.kernelPackages = pkgs.linuxPackages_latest;
hardware.enableRedistributableFirmware = true;
boot.kernelParams = [ "lsm=landlock,lockdown,yama,integrity,apparmor,bpf" "audit=1" ];
```

### Open sub-decision: one passphrase prompt or two

With `/boot` inside LUKS, GRUB prompts for the passphrase, then the initrd prompts **again**.
Recommended fix — and it is safe *specifically because* of this design: the initrd itself lives on the
encrypted `/boot`, so a keyfile embedded in it is already protected.

- add the keyfile as a second LUKS key slot (`additionalKeyFiles`),
- `boot.initrd.secrets."/crypto_keyfile.bin" = "/boot/crypto_keyfile.bin";`
- `boot.initrd.luks.devices.cryptroot.keyFile = "/crypto_keyfile.bin";`

If this misbehaves on install day, just accept the double prompt — it is cosmetic, not functional.

---

## 5. Graphics: `modules/nixos/hardware/amd.nix` (new)

`common-gpu-amd` already sets `videoDrivers = [ "modesetting" ]`, `hardware.graphics.enable`,
`enable32Bit`, and `hardware.amdgpu.initrd.enable`. This module adds only what it does not:

```nix
hardware.cpu.amd.updateMicrocode = true;
environment.variables = {
  LIBVA_DRIVER_NAME = "radeonsi";
  VDPAU_DRIVER      = "radeonsi";
};
environment.systemPackages = with pkgs; [ libva-utils vulkan-tools radeontop ];
```

Nothing else is needed — radeonsi VA-API and RADV ship inside mesa (26.1.5 in this pin).

⚠️ The critical part is a *removal*: `hardware/intel.nix` sets `LIBVA_DRIVER_NAME=iHD` and
`i915.*` kernel params **globally**. It must not be imported by this host.

---

## 6. Power: `modules/nixos/hardware/power-amd.nix` (new)

`power.nix` is Intel-shaped and stays for the samsung host. Three concrete problems it has on AMD:

1. `CPU_SCALING_GOVERNOR_ON_AC = "performance"` — under `amd-pstate-epp` this **disables EPP's dynamic
   scaling** and pins clocks high. The AMD-correct shape is `powersave` on both, with EPP doing the work.
2. `CPU_HWP_DYN_BOOST_ON_AC/BAT` — Intel HWP only, no-op here.
3. `services.undervolt` — Intel-only.

New module (TLP 1.9.1 in this pin supports all of these):

```nix
services.power-profiles-daemon.enable = false;
services.tlp = {
  enable = true;
  settings = {
    CPU_DRIVER_OPMODE_ON_AC      = "active";
    CPU_DRIVER_OPMODE_ON_BAT     = "active";
    CPU_SCALING_GOVERNOR_ON_AC   = "powersave";
    CPU_SCALING_GOVERNOR_ON_BAT  = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
    CPU_BOOST_ON_AC  = 1;
    CPU_BOOST_ON_BAT = 0;
    PLATFORM_PROFILE_ON_AC  = "performance";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    # thinkpad_acpi battery care — the machine lives docked, battery has 9 cycles
    START_CHARGE_THRESH_BAT0 = 75;
    STOP_CHARGE_THRESH_BAT0  = 80;
    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";
    SOUND_POWER_SAVE_ON_BAT = 1;
    NMI_WATCHDOG = 0;
    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";
  };
};
environment.systemPackages = with pkgs; [ powertop acpi ];
```

Dropped vs the Intel module: `DISK_SPINDOWN_TIMEOUT_*` (meaningless on NVMe), `CPU_HWP_DYN_BOOST_*`,
`services.undervolt`, `acpid`.

---

## 7. Fingerprint

### 7.1 System side

```nix
services.fprintd.enable = true;
security.pam.services.sudo.fprintAuth  = true;
security.pam.services.slock.fprintAuth = true;   # also *creates* /etc/pam.d/slock — required, see below
```

`login.fprintAuth` is **not** set: `services.getty.autologinUser = "frank"` means there is no login
password prompt to improve. Password fallback stays intact everywhere.

Enrollment is a post-install step (`fprintd-enroll`, ~30 s). `/var/lib/fprint` is **not** worth backing
up — re-enroll on the fresh install.

### 7.2 slock — upstream fork changes (github.com/andre-gonzalez/slock)

Two findings drive this:

- The fork is a **finalized flexipatch**: zero `_PATCH` guards remain in the 446-line `slock.c`. Flipping
  `PAMAUTH_PATCH` to 1 in `patches.h` does nothing — the PAM code was stripped by flexipatch-finalizer.
  `slock.c` authenticates via `getspnam()` + `crypt()` directly, so **fingerprint unlock is impossible
  as built**.
- Therefore: hand-apply the suckless `pam_auth` patch to the flattened source.

Commit to the fork:
1. Apply <https://tools.suckless.org/slock/patches/pam_auth/> to `slock.c`.
2. `config.mk`: uncomment `PAM=-lpam`.
3. `config.def.h` / `config.h`: `static const char *pam_service = "slock";` (the patch defaults to
   Arch's `"login"` — it must match the NixOS PAM service name above).
4. Bump `rev` in `pkgs/slock/default.nix`.

### 7.3 slock — Nix derivation changes (this repo)

**slock is already broken on NixOS today, independent of fingerprint.** The committed `config.h` has
`group = "nobody"` (the comment literally says *"use nobody for arch"*). NixOS ships **`nogroup`**, not
`nobody` — verified against the pinned nixpkgs. `getgrnam("nobody")` fails and slock dies at startup.

Distro-specific, so it belongs in the packaging layer, not the fork:

```nix
postPatch = ''
  substituteInPlace Makefile --replace-quiet "chmod u+s" "true"
  substituteInPlace config.h --replace 'group = "nobody"' 'group = "nogroup"'
'';
```

Note the replacement targets the **group** line only — `user = "nobody"` is correct and must stay.

After the PAM switch, `security.wrappers.slock` (in `desktop/xorg.nix`) may no longer be needed, since
PAM delegates shadow reads to the setuid `unix_chkpwd` helper. Keep the wrapper initially, verify, then
remove in a follow-up rather than in the same change.

---

## 8. WiFi

Keep iwd — it is what both Arch and `hosts/samsung-expert` use, and all 16 known networks are PSK or
open (`_Free_JFK_Wi-Fi`, `#SFO FREE WIFI`, `aainflight.com`, …). **No 802.1X anywhere**, so nothing
forces NetworkManager.

Port from the samsung host into `hosts/t14/default.nix`:

- `networking.wireless.iwd.enable` with `General.EnableNetworkConfiguration = true` and
  `Network.NameResolvingService = "systemd"`.
- `systemd.tmpfiles.rules = [ "d /var/lib/iwd 0700 root root -" ]`.
- `age.secrets."iwd-QUEWIFI-5G"` → `/var/lib/iwd/QUEWIFI-5G.psk`, mode `0600`, `symlink = false`.

`secrets/secrets.nix`: replace the `workstation = "ssh-ed25519 AAAA_REPLACE_WITH_WORKSTATION_HOST_KEY"`
placeholder with the real **t14** host key, rename the binding, and re-encrypt:

- `iwd-QUEWIFI-5G.age` — currently encrypted to **samsung + frank only**, so t14 cannot read it.
- `aws-credentials.age` — currently listed for the placeholder `workstation` key.
- everything in `allHosts` (ssh-port, tailscale-authkey, neomutt ×3, msmtp, mbsyncrc, rclone).

The other 15 networks come back by restoring `/var/lib/iwd` from the pre-wipe backup.

---

## 9. Displays

Profiles stay in the dotfiles bare repo. The flake side already works: `desktop/autorandr.nix` enables
`services.autorandr`, which installs the hotplug udev rule.

Back up `~/.config/autorandr/` (profiles `docked` + `laptop` and the `postswitch` hook) before the wipe —
`disko` destroys it.

Two things to fix in dotfiles while you are in there (not blocking):

- The commented xrandr block in `.xinitrc` references `eDP-1` / `HDMI-1`. On amdgpu the outputs are
  **`eDP`** and **`HDMI-A-0`**.
- `postswitch` runs `setxkbmap -layout us -variant dvorak-intl -option caps:escape`, `.xinitrc` runs
  `-variant dvorak-intl -option caps:swapescape`, and `desktop/xorg.nix` declares `variant = "dvorak"`
  with `options = "caps:escape"`, while `base/locale.nix` sets console `keyMap = "dvorak"`. Three
  different answers. Worth reconciling on `dvorak-intl`.

---

## 10. Laptop behaviours

**Lock on suspend** (nothing like this exists on Arch — only xautolock's 10-minute idle timer, so a
closed lid today is an unlocked machine):

```nix
systemd.services.slock-suspend = {
  description = "Lock X session with slock before sleep";
  before = [ "sleep.target" ];
  wantedBy = [ "sleep.target" ];
  serviceConfig = {
    Type = "forking";
    User = "frank";
    Environment = "DISPLAY=:0";
    ExecStart = "${config.security.wrappers.slock or "…"}/bin/slock";
  };
};
```

logind defaults are already correct for your usage — `HandleLidSwitchDocked = ignore` applies whenever an
external display is connected, which is the docked-with-ultrawide case. Set explicitly in the host file
anyway, as documentation of intent.

**Brightness Fn keys** — currently bound *nowhere*: `.xbindkeysrc` has volume and media keys but no
`XF86MonBrightness*`, and `brightnessctl` in `systemPackages` does not install its udev rules.

```nix
services.udev.packages = [ pkgs.brightnessctl ];
```

frank is already in the `video` group (`base/users.nix`). Then add to `.xbindkeysrc` in dotfiles:

```
"brightnessctl set +10%"
  XF86MonBrightnessUp
"brightnessctl set 10%-"
  XF86MonBrightnessDown
```

**fwupd** — `services.fwupd.enable = true;`. Lenovo ships T14 UEFI, EC and Synaptics fingerprint firmware
through LVFS; you are on BIOS 1.19.

---

## 11. Pre-wipe checklist — do these **on Arch, before disko runs**

Ordering matters: items 1–3 must be committed and pushed *before* the disk is erased.

1. **Generate the t14 agenix host key** and keep the private half somewhere off-machine:
   `ssh-keygen -t ed25519 -N "" -C root@t14 -f ./.extra-files/t14/etc/ssh/ssh_host_ed25519_key`
2. **Update `secrets/secrets.nix`** — replace the `workstation` placeholder with this pubkey, rename to
   `t14`, add `t14` to `iwd-QUEWIFI-5G.age` and `aws-credentials.age`.
3. **Re-encrypt every secret** with `agenix -r`, commit, **push**.
4. **Commit and push the slock PAM patch** to the fork; bump the rev here.
5. **Back up**, verified off-machine:
   - `~/` in full, or at minimum: the dotfiles bare repo *and confirm it is pushed*, `~/.ssh`, `~/.gnupg`,
     `~/.config/autorandr`, `~/.config/dwm`, `~/.config/dwmblocks`, `~/.Xresources`, `~/.xinitrc`,
     `~/.xbindkeysrc`, `~/.scripts`, `~/projects`
   - `sudo tar czf iwd-backup.tar.gz -C /var/lib iwd` — root-owned, 0700, and the *only* copy of 15 WiFi
     passwords
   - `pacman -Qqe > arch-packages.txt` — reference for anything the flake is still missing (§13)
6. Confirm the flake evaluates: `nix flake check` / `nix eval .#nixosConfigurations.t14.config.system.build.toplevel.drvPath`

---

## 12. Install runbook

Adapted from `INSTALL.md` (written for samsung-expert), which already has the right shape including
"inject the agenix host key **before** reboot".

1. Boot the NixOS ISO on the T14.
2. `nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#t14`
   — ⚠️ erases `/dev/nvme0n1`. Prompts for the new LUKS passphrase.
3. `nixos-generate-config --no-filesystems --root /mnt` → commit as `hosts/t14/hardware-configuration.nix`
   (`--no-filesystems` keeps disko in charge of mounts).
4. `nixos-install --flake .#t14 --no-root-password`
5. Copy `.extra-files/t14/etc/ssh/ssh_host_ed25519_key*` to `/mnt/etc/ssh/` (mode 0600) **before reboot**,
   so agenix can decrypt the WiFi PSK on first boot.
6. Reboot, remove the USB.
7. Restore `/var/lib/iwd` from the backup (`0700 root:root`, `.psk` files `0600`), restore
   `~/.config/autorandr`, re-clone the dotfiles bare repo.
8. `fprintd-enroll` as frank.

---

## 13. Post-install verification

| Check | Command / expectation |
|---|---|
| GPU | `lsmod \| grep amdgpu`; `vainfo` reports **radeonsi**; `glxinfo -B` shows Radeon 860M |
| Fingerprint | `fprintd-list frank`; `sudo -k && sudo -v` prompts for finger, Ctrl-C falls back to password |
| slock | locks and **unlocks by finger**; confirm it no longer dies on `getgrnam` |
| Boot | one passphrase prompt (or two, if the initrd keyfile was skipped) |
| Swap | `swapon --show` — zram at priority 100, `/swap/swapfile` below it |
| Power | `tlp-stat -p` shows governor `powersave` + EPP `performance`/`balance_power` |
| Battery | `cat /sys/class/power_supply/BAT0/charge_control_end_threshold` → `80` |
| WiFi | `iwctl station wlan0 get-networks`; auto-connects to QUEWIFI-5G on first boot |
| Audio | `pactl list sinks short`; speakers **and** internal mic (`snd_soc_dmic`) both work |
| Suspend | close lid undocked → suspends and locks; docked → ignores lid |
| Brightness | `XF86MonBrightnessUp/Down` move `amdgpu_bl1` |
| Firmware | `fwupdmgr get-devices` lists UEFI + fingerprint sensor |
| Dock | HDMI hotplug flips autorandr `laptop` ↔ `docked` |

---

## 14. Flagged, not decided

Surfaced during the review; none block the install.

1. **dwm is packaged twice for no reason.** `pkgs/dwm/laptop.nix` and `pkgs/dwm/ultrawide.nix` pin the
   *same* repo and *same* rev, and `~/.config/autorandr/postswitch` explicitly says *"dwm is no longer
   switched from here. One build serves both layouts"*. `modules/home/desktop/dwm.nix` still installs
   both. Consolidate to a single `dwm` derivation. (You have stale local branches
   `change-dwm-to-a-single-binary` / `add-dwm-as-a-single-binary` for this.)
2. **Keyboard variant is inconsistent** across four places — see §9.
3. **`.xinitrc` launches programs the flake does not provide**: `insync`, `clipmenud`, `playerctld`
   (`playerctl`), `dash`, plus `~/.scripts/kill-xautolock.sh` and `random-wallpaper.sh`. `.xbindkeysrc`
   also calls `pactl` while the flake installs `pamixer`. Cross-check against `arch-packages.txt`.
4. **`base/users.nix` sudo rule** allows `/usr/bin/umount /mnt/backup*` — an Arch path that does not
   exist on NixOS; the `/run/current-system/sw/bin` variant below it is the effective one.
5. **`virtualization/windows-vm.nix` is entirely commented out** — importing it is currently a no-op.
6. **NPU (`amdxdna`)** loads but has no userspace (XRT/ROCm). Out of scope unless you want it.
7. **TPM + Secure Boot** are unused. The GRUB choice rules out lanzaboote; GRUB's TPM2 key-protector
   patches *are* present in nixpkgs if passphrase-less unlock ever becomes interesting.
