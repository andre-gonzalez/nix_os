# NixOS Configuration Structure

## Dendritic Module Structure

| Directory | Contents |
|---|---|
| `flake.nix` | Root: inputs (nixpkgs-unstable, home-manager, agenix, disko, nixos-hardware), both host configs, custom package exports |
| `hosts/t14/` | ThinkPad T14 Gen 6 (AMD) — imports base + desktop + btrfs + amd + power(+amd,+thinkpad) + disko-btrfs-luks + docker + tailscale + libvirt + home-manager. Adds LUKS/GRUB, iwd, fprintd, lock-on-suspend, fwupd. Replaces the old `workstation` host. See `hosts/t14/INSTALL.md`. |
| `hosts/samsung-expert/` | Laptop host — imports base + desktop + btrfs + intel + power(+intel) + disko-btrfs-luks + tailscale + docker + libvirt; QCA9377 WiFi (iwd), nouveau disabled, GRUB to the removable EFI path; the only host with a SATA disk. Local USB install, see `INSTALL.md`. |
| `modules/nixos/base/` | users, locale (Dvorak/São Paulo), packages, ssh hardening, fail2ban, faillock, ClamAV, nftables firewall, network/resolved, fish, SSD-gated fstrim |
| `modules/nixos/desktop/` | xorg (startx/autologin), pipewire, bluetooth, fonts (Noto/Nerd/JoyPixels), autorandr |
| `modules/nixos/hardware/` | intel VA-API, amd VA-API, nvidia-open, btrfs+snapper; TLP power split into `power.nix` (vendor-neutral) + `power-amd.nix` / `power-intel.nix` (pick one) + `power-thinkpad.nix` (charge thresholds, platform profile); disko btrfs (plain + LUKS) |
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
