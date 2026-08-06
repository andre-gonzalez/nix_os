# NixOS Configuration Structure

## Dendritic Module Structure

| Directory | Contents |
|---|---|
| `flake.nix` | Root: inputs (nixpkgs-unstable, home-manager, agenix, disko, nixos-hardware), both host configs, custom package exports |
| `hosts/workstation/` | Desktop host — imports base + desktop + btrfs + docker + tailscale + libvirt + home-manager |
| `hosts/samsung-expert/` | Laptop host — imports base + desktop + intel + power + tailscale; Broadcom WiFi + drive mounts |
| `modules/nixos/base/` | users, locale (Dvorak/São Paulo), packages, ssh hardening, AppArmor/fail2ban/auditd, nftables firewall, network/resolved, fish, SSD-gated fstrim |
| `modules/nixos/desktop/` | xorg (startx/autologin), pipewire, bluetooth, fonts (Noto/Nerd/JoyPixels), autorandr |
| `modules/nixos/hardware/` | intel VA-API, nvidia-open, btrfs+snapper+grub-btrfs, TLP power |
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
