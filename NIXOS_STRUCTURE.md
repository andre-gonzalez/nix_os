# NixOS Configuration Structure

## Dendritic Module Structure

| Directory | Contents |
|---|---|
| `flake.nix` | Root: inputs (nixpkgs-unstable, home-manager, agenix, disko, nixos-hardware), both host configs, custom package exports |
| `hosts/workstation/` | ThinkPad T14 Gen 6 (AMD) — imports base + desktop + btrfs + power(+amd,+thinkpad) + docker + tailscale + libvirt + home-manager |
| `hosts/samsung-expert/` | Laptop host — imports base + desktop + intel + power(+intel) + tailscale; Broadcom WiFi + drive mounts; the only host with a SATA disk |
| `modules/nixos/base/` | users, locale (Dvorak/São Paulo), packages, ssh hardening, AppArmor/fail2ban/auditd, nftables firewall, network/resolved, fish, SSD-gated fstrim |
| `modules/nixos/desktop/` | xorg (startx/autologin), pipewire, bluetooth, fonts (Noto/Nerd/JoyPixels), autorandr |
| `modules/nixos/hardware/` | intel VA-API, nvidia-open, btrfs+snapper+grub-btrfs; TLP power split into `power.nix` (vendor-neutral) + `power-amd.nix` / `power-intel.nix` (pick one) + `power-thinkpad.nix` (charge thresholds, platform profile) |
| `modules/nixos/services/` | tailscale, docker, snapper, preload |
| `modules/nixos/virtualization/` | libvirtd+KVM, windows-vm stub |
| `modules/home/` | Full Home Manager: fish/tmux, all desktop tools, neovim/git/zathura/mpv/qutebrowser/newsboat/lf/zoxide, work tools, services |
| `pkgs/` | Custom derivations for dwm, st, dmenu, slock, dwmblocks, dwmstatus, wall-d, notas, stw |
| `overlays/` | Package overrides/pins |
| `secrets/secrets.nix` | agenix manifest with placeholders for all secrets from the plan |

## Key Things To Do Next

1. Replace placeholder public keys in `secrets/secrets.nix` with actual host + personal age keys
2. Run `nixos-generate-config` on each machine → commit to `hosts/*/hardware-configuration.nix`
3. Pin `rev` in each `pkgs/*/` derivation after the first successful build
4. Note the `snapper.nix` service module re-imports `btrfs.nix` — on the workstation host which imports both directly, remove the `services/snapper.nix` import and keep only `hardware/btrfs.nix` to avoid double-import
