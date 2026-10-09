# NixOS Configuration Structure

## Dendritic Module Structure

| Directory | Contents |
|---|---|
| `flake.nix` | Root: inputs (nixpkgs-unstable, nixpkgs-stable for servarr, home-manager, agenix, disko, nixos-hardware), all host configs, custom package exports |
| `hosts/t14/` | ThinkPad T14 Gen 6 (AMD) — imports base + workstation + desktop + btrfs + amd + power(+amd,+thinkpad) + disko-btrfs-luks + docker + tailscale + libvirt + home-manager. Adds LUKS/GRUB, iwd, fprintd, lock-on-suspend, fwupd. Replaces the old `workstation` host. See `hosts/t14/INSTALL.md`. |
| `hosts/samsung-expert/` | Laptop host — imports base + workstation + desktop + btrfs + intel + power(+intel) + disko-btrfs-luks + tailscale + docker + libvirt; QCA9377 WiFi (iwd), nouveau disabled, GRUB to the removable EFI path; the only host with a SATA disk. Local USB install, see `INSTALL.md`. |
| `hosts/servarr/` | Homelab Docker Compose server (Proxmox VM), built from **nixpkgs-stable** (26.05) — imports base + disko-ext4 + tailscale + docker, no Home Manager. Adds SSH key+TOTP for frank, the CI `deploy` user (forced command `ci/deploy.sh`), the `/opt/servarr` checkout and its agenix `.env`, NFS `/mnt/media`, resolved without stub (Pi-hole owns :53), the Radicale mirror timer. Install and cutover from Debian: `hosts/servarr/INSTALL.md`. |
| `modules/nixos/base/` | Every host, servers included: users, locale (Dvorak/São Paulo), core packages, ssh hardening, fail2ban, faillock, nftables firewall, network/resolved, fish, SSD-gated fstrim |
| `modules/nixos/workstation/` | Laptops only, on top of base: frank's personal secrets (agenix → Home Manager), desktop/dev/work packages, ClamAV |
| `modules/nixos/desktop/` | xorg (startx/autologin), pipewire, bluetooth, fonts (Noto/Nerd/JoyPixels), autorandr |
| `modules/nixos/hardware/` | intel VA-API, amd VA-API, nvidia-open, btrfs+snapper; TLP power split into `power.nix` (vendor-neutral) + `power-amd.nix` / `power-intel.nix` (pick one) + `power-thinkpad.nix` (charge thresholds, platform profile); disko btrfs (plain + LUKS), disko ext4 (servers) |
| `modules/nixos/services/` | tailscale, docker, snapper |
| `modules/nixos/virtualization/` | libvirtd+KVM (Windows runs in Docker: ~/projects/windows-docker, cloned by home/repos.nix) |
| `modules/home/` | Full Home Manager: fish/tmux, all desktop tools, neovim/git/zathura/mpv/qutebrowser/newsboat/lf/zoxide, work tools, services |
| `pkgs/` | Custom derivations for dwm, st, dmenu, slock, dwmblocks, dwmstatus, wall-d, notas, stw |
| `overlays/` | Package overrides/pins |
| `secrets/secrets.nix` | agenix manifest with placeholders for all secrets from the plan |

## Key Things To Do Next

1. Replace placeholder public keys in `secrets/secrets.nix` with actual host + personal age keys
2. Run `nixos-generate-config` on each machine → commit to `hosts/*/hardware-configuration.nix`
3. Pin `rev` in each `pkgs/*/` derivation after the first successful build
4. The `snapper.nix` service module is a thin re-export of `hardware/btrfs.nix`. Import only one of the two per host — `hosts/t14/` imports `hardware/btrfs.nix` alone; the old `workstation` host imported both.
