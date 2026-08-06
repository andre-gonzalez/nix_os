# NixOS Migration Plan

Migrate André Gonzalez's Arch Linux workstation to NixOS, replicating every configuration
currently managed by this Ansible repository. The target configuration follows NixOS best
practices using Flakes, Home Manager, and a **dendritic module structure** — a tree of
composable, single-concern modules that machines import selectively.

---

## 1. Core Architecture Decisions

| Concern | Choice | Rationale |
|---|---|---|
| Config format | **Flakes** | Reproducible, pinned deps, standard today |
| Package channels | **nixpkgs-unstable** + stable overlay | Mirrors AUR-level freshness from Arch |
| User environment | **Home Manager** (standalone, flake-based) | Separates system from user config |
| Secrets | **agenix** (age-encrypted, per-host keys) | Replaces ansible-vault; git-safe |
| Custom builds (dwm, st, dmenu, slock) | **`pkgs.callPackage` overrides in `pkgs/`** | Keeps suckless src patching in-tree |
| Display config | **autorandr** + NixOS `services.xserver` | Direct port of existing autorandr profiles |
| Btrfs snapshots | **snapper** via NixOS module | Same tooling, declarative config |
| Boot | **GRUB + grub-btrfs** | Preserves snapshot boot entries |

---

## 2. Repository Structure (Dendritic Pattern)

```
nixos-config/
├── flake.nix                          # Root: inputs, outputs, nixosConfigurations
├── flake.lock
│
├── hosts/                             # One directory per machine
│   ├── workstation/                   # Main desktop (migrating from Arch)
│   │   ├── default.nix                # Imports modules + machine-specific overrides
│   │   ├── hardware-configuration.nix # nixos-generate-config output (do NOT hand-write)
│   │   └── disko.nix                  # Optional: declarative disk/btrfs layout (disko)
│   └── samsung-expert/                # Samsung Expert Book laptop
│       ├── default.nix
│       └── hardware-configuration.nix
│
├── modules/
│   ├── nixos/                         # System-level NixOS modules
│   │   ├── base/
│   │   │   ├── default.nix            # Imports all base sub-modules
│   │   │   ├── users.nix              # frank + ansible users, groups, umask
│   │   │   ├── locale.nix             # Timezone, locale, keyboard (vconsole)
│   │   │   ├── packages.nix           # Base system packages (git, btop, ansible…)
│   │   │   ├── ssh.nix                # sshd hardening, authorized_keys from GitHub
│   │   │   ├── security.nix           # Apparmor, fail2ban, auditd, password policy
│   │   │   ├── network.nix            # DNS (1.1.1.3), systemd-resolved
│   │   │   ├── firewall.nix           # nftables/UFW rules, block ping, tailscale allow
│   │   │   └── fish.nix               # System-wide fish shell default
│   │   │
│   │   ├── desktop/
│   │   │   ├── default.nix            # Imports all desktop sub-modules
│   │   │   ├── xorg.nix               # xorg-server, xinit, xrandr, xsetroot, setxkbmap
│   │   │   ├── audio.nix              # Pipewire + wireplumber, alsa, pulse compat
│   │   │   ├── bluetooth.nix          # bluetoothd service
│   │   │   ├── fonts.nix              # Noto, Liberation, DejaVu, nerd-fonts, JoyPixels
│   │   │   └── autorandr.nix          # autorandr service + profiles (docked/laptop)
│   │   │
│   │   ├── hardware/
│   │   │   ├── intel.nix              # intel-media-driver, i915 module, TLP Intel tune
│   │   │   ├── nvidia.nix             # nvidia-open or legacy driver, envycontrol
│   │   │   ├── btrfs.nix              # kernel btrfs support, grub-btrfs, snapper
│   │   │   └── power.nix              # TLP, powertop, intel-undervolt (notebooks only)
│   │   │
│   │   ├── services/
│   │   │   ├── tailscale.nix          # tailscale service, firewall exception
│   │   │   ├── docker.nix             # docker daemon, frank in docker group
│   │   │   ├── snapper.nix            # snapper configs for / and /home, timers
│   │   │   └── preload.nix            # preload daemon
│   │   │
│   │   └── virtualization/
│   │       ├── libvirt.nix            # KVM/QEMU, virt-manager, libvirtd service
│   │       └── windows-vm.nix         # Windows VM definition (if desired declaratively)
│   │
│   └── home/                          # Home Manager modules (user-space)
│       ├── default.nix                # Imports all home sub-modules
│       │
│       ├── shell/
│       │   ├── fish.nix               # Fish config, oh-my-fish equivalent, aliases
│       │   └── tmux.nix               # tmux + tmuxp config
│       │
│       ├── desktop/
│       │   ├── dwm.nix                # Custom suckless build via callPackage
│       │   ├── st.nix                 # Simple Terminal custom build
│       │   ├── dmenu.nix              # dmenu custom build
│       │   ├── slock.nix              # slock custom build
│       │   ├── dwmblocks.nix          # dwmblocks status bar
│       │   ├── picom.nix              # picom compositor config
│       │   ├── dunst.nix              # dunst notification config
│       │   ├── feh.nix                # feh as image viewer + wallpaper
│       │   └── xbindkeys.nix          # Key bindings
│       │
│       ├── programs/
│       │   ├── neovim.nix             # Neovim + plugins, set as git editor
│       │   ├── git.nix                # git identity, delta, config
│       │   ├── zathura.nix            # PDF viewer, set as xdg default
│       │   ├── mpv.nix                # mpv config
│       │   ├── qutebrowser.nix        # qutebrowser config
│       │   ├── newsboat.nix           # RSS reader config
│       │   ├── lf.nix                 # lf file manager (lfub)
│       │   ├── anki.nix               # Anki flashcards
│       │   ├── calibre.nix            # eBook management
│       │   └── zoxide.nix             # zoxide + fzf integration
│       │
│       ├── work/
│       │   ├── neomutt.nix            # neomutt multi-account config
│       │   ├── aws.nix                # aws-cli config and credentials symlinks
│       │   ├── datagrip.nix           # DataGrip IDE
│       │   ├── cursor.nix             # Cursor AI editor
│       │   ├── onepassword.nix        # 1Password desktop + CLI
│       │   └── slack.nix              # Slack
│       │
│       └── services/
│           ├── redshift.nix           # Redshift (color temperature)
│           ├── rclone.nix             # rclone sync jobs as systemd user services
│           └── syncthing.nix          # Syncthing (currently disabled, easy to toggle)
│
├── pkgs/                              # Custom package derivations
│   ├── default.nix                    # Exports all custom packages
│   ├── dwm/                           # dwm builds
│   │   ├── laptop.nix                 # laptop-dwm branch build
│   │   └── ultrawide.nix              # ultra-wide-dwm branch build
│   ├── st/default.nix                 # st build from your repo
│   ├── dmenu/default.nix
│   ├── slock/default.nix
│   ├── dwmblocks/default.nix
│   ├── dwmstatus/default.nix
│   ├── wall-d/default.nix
│   ├── notas/default.nix
│   └── stw/default.nix
│
├── overlays/
│   └── default.nix                    # Pins AUR-equivalent packages to nixpkgs-unstable
│                                      # or overrides where needed
│
└── secrets/
    ├── secrets.nix                    # agenix: list of secrets + which host keys can decrypt
    ├── ssh-port.age                   # SSH port number
    ├── tailscale-authkey.age          # Tailscale auth key
    ├── wifi-lopes.age                 # WiFi PSK files
    ├── wifi-lnam5.age
    ├── wifi-queWifi2.age
    ├── wifi-casaRio5g.age
    ├── aws-credentials.age            # AWS credentials
    ├── neomutt-personal.age           # Mutt configs per account
    ├── neomutt-uberall.age
    ├── neomutt-athenaworks.age
    ├── msmtp.age
    ├── mbsyncrc.age
    └── rclone.age
```

---

## 3. flake.nix Skeleton

```nix
{
  description = "André Gonzalez – NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05"; # adjust to current stable

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hardware quirks database (Samsung Expert Book, etc.)
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { self, nixpkgs, home-manager, agenix, disko, nixos-hardware, ... } @ inputs: {
    nixosConfigurations = {
      workstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/workstation/default.nix
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
          disko.nixosModules.disko
        ];
      };

      samsung-expert = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/samsung-expert/default.nix
          nixos-hardware.nixosModules.samsung-galaxy-book  # or closest match
          home-manager.nixosModules.home-manager
          agenix.nixosModules.default
        ];
      };
    };
  };
}
```

---

## 4. Module Implementation Guide

### 4.1 Base — `modules/nixos/base/`

#### users.nix
```nix
# Key mappings from Ansible roles/base/tasks/users.yml
users.users.frank = {
  isNormalUser = true;
  extraGroups = [ "wheel" "adm" "audio" "video" "docker" "audit" ];
  shell = pkgs.fish;
  openssh.authorizedKeys.keyFiles = [
    # fetched once and committed, or fetched at build time
    # URL: https://github.com/andre-gonzalez.keys
  ];
};
security.sudo.extraRules = [{
  users = [ "frank" ];
  commands = [{ command = "ALL"; options = [ "PASSWD" ]; }];
}];
# aur_builder equivalent not needed on NixOS
```

#### ssh.nix
```nix
# Mirrors roles/base/tasks/ssh.yml
services.openssh = {
  enable = true;
  ports = [ config.age.secrets.ssh-port.value ];   # via agenix
  settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    X11Forwarding = false;
    AllowTcpForwarding = false;
    AllowAgentForwarding = false;
    MaxAuthTries = 3;
    MaxSessions = 2;
    ClientAliveCountMax = 2;
    TCPKeepAlive = false;
    LogLevel = "VERBOSE";
    Banner = "/etc/issue.net";
  };
};
# AllowUsers set via extraConfig if needed
```

#### security.nix
```nix
# Mirrors roles/base/tasks/security.yml
security.apparmor.enable = true;
security.auditd.enable = true;
services.fail2ban = {
  enable = true;
  jails.DEFAULT.settings = { /* port, bantime, maxretry */ };
  jails.sshd = { /* ssh-specific jail */ };
};
# Core dumps disabled
security.pam.loginLimits = [
  { domain = "*"; item = "core"; type = "hard"; value = "0"; }
];
# Umask
security.loginDefs.settings.UMASK = "027";
# Password aging
security.loginDefs.settings = {
  PASS_MAX_DAYS = 180;
  PASS_MIN_DAYS = 1;
  PASS_WARN_AGE = 30;
  SHA_CRYPT_MIN_ROUNDS = 5000;
};
```

#### firewall.nix
```nix
# Mirrors roles/base/tasks/ufw.yml
# NixOS uses nftables by default now; can also enable ufw
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ ];   # SSH port is handled via allowedTCPPortRanges or per-interface
  extraInputRules = ''
    # Allow SSH from local network only
    ip saddr 192.168.0.0/24 tcp dport ${toString sshPort} accept
    # Drop ICMP echo requests
    icmp type echo-request drop
  '';
  trustedInterfaces = [ "tailscale0" ];
};
services.tailscale.enable = true;
```

#### network.nix
```nix
# Mirrors roles/base/tasks/network.yml
services.resolved = {
  enable = true;
  fallbackDns = [ "1.1.1.3" "1.0.0.3" ];
};
# For workstation with iwd:
networking.wireless.iwd = {
  enable = true;
  settings = { /* global iwd settings */ };
};
# WiFi networks via agenix-decrypted PSK files placed in /var/lib/iwd/
```

---

### 4.2 Desktop — `modules/nixos/desktop/`

#### xorg.nix
```nix
# Mirrors roles/light_workstation dwm boot flow
services.xserver = {
  enable = true;
  displayManager.startx.enable = true;  # no display manager, startx from tty
  windowManager.dwm.enable = false;     # we use our own custom build from pkgs/
};
# Autologin to tty1 mirrors systemd getty config
services.getty.autologinUser = "frank";
```

#### audio.nix
```nix
# Mirrors roles/light_workstation/tasks/audio.yml
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  jack.enable = true;
  wireplumber.enable = true;
};
```

---

### 4.3 Hardware — `modules/nixos/hardware/`

#### btrfs.nix
```nix
# Mirrors roles/light_workstation/tasks/snapper.yml + grub.yml
services.snapper = {
  configs = {
    root = { SUBVOLUME = "/"; ALLOW_USERS = [ "frank" ]; };
    home = { SUBVOLUME = "/home"; ALLOW_USERS = [ "frank" ]; };
  };
};
services.btrfs.autoScrub.enable = true;
boot.supportedFilesystems = [ "btrfs" ];
# grub-btrfs handled via boot.loader.grub.extraEntries or grub-btrfs package hook
```

#### power.nix
```nix
# Mirrors roles/light_workstation/tasks/save-battery.yml
# Only applied to notebook hosts
services.tlp = {
  enable = true;
  settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 0;
    CPU_HWP_DYN_BOOST_ON_AC = 1;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;
    DISK_SPINDOWN_TIMEOUT_ON_BAT = "0 1";
    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";
  };
};
```

---

### 4.4 Suckless Custom Builds — `pkgs/`

Each suckless tool (dwm, st, dmenu, slock) is built by pointing `src` at your
private GitHub repository and applying the same patches. Example for dwm:

```nix
# pkgs/dwm/laptop.nix
{ stdenv, lib, fetchgit, xorg, ... }:
stdenv.mkDerivation {
  pname = "dwm-laptop";
  version = "unstable";
  src = fetchgit {
    url = "git@github.com:andre-gonzalez/dwm.git";
    rev = "HEAD";               # or pin to a specific commit
    branchName = "laptop-dwm";
    fetchSubmodules = false;
    sha256 = lib.fakeSha256;    # run nix build once to get real hash
  };
  buildInputs = [ xorg.libX11 xorg.libXft xorg.libXinerama ];
  installPhase = ''
    mkdir -p $out/bin
    cp dwm $out/bin/
  '';
}
```

The `config.h` changes live in your git branch, so no patching needed in Nix.
For private repos, use an SSH key or a deploy token via `builtins.fetchGit`
with SSH agent forwarding, or host a mirror.

---

### 4.5 Secrets Management — `secrets/`

Replace `ansible-vault` with **agenix**:

1. Each secret is an age-encrypted file committed to the repo
2. Decryption keys are the SSH host keys of each machine + your personal key
3. At activation time, NixOS decrypts to `/run/agenix/`

**secrets/secrets.nix:**
```nix
let
  workstation = "ssh-ed25519 AAAA... root@workstation";
  samsung     = "ssh-ed25519 AAAA... root@samsung";
  frank       = "age1..."; # derived from your personal SSH key
in {
  "ssh-port.age".publicKeys          = [ workstation samsung frank ];
  "tailscale-authkey.age".publicKeys = [ workstation samsung frank ];
  "wifi-lopes.age".publicKeys        = [ workstation samsung frank ];
  "aws-credentials.age".publicKeys   = [ workstation frank ];
  "neomutt-personal.age".publicKeys  = [ workstation samsung frank ];
  # ... etc
}
```

**Migration from ansible-vault:**
```bash
# For each secret: decrypt with ansible-vault, re-encrypt with agenix
ansible-vault decrypt --output=- <file> | agenix -e secrets/<name>.age
```

---

## 5. Host Profiles

### hosts/workstation/default.nix
```nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware/btrfs.nix
    ../../modules/nixos/hardware/nvidia.nix  # if applicable
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/docker.nix
    ../../modules/nixos/services/snapper.nix
    ../../modules/nixos/virtualization/libvirt.nix
  ];

  # Machine-specific overrides
  networking.hostName = "workstation";

  # Home Manager wired in at system level
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.frank = import ../../modules/home;
    extraSpecialArgs = { inherit inputs; };
  };

  system.stateVersion = "25.05"; # set once, do not update
}
```

### hosts/samsung-expert/default.nix
```nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base
    ../../modules/nixos/desktop
    ../../modules/nixos/hardware/btrfs.nix
    ../../modules/nixos/hardware/intel.nix   # intel-media-driver
    ../../modules/nixos/hardware/power.nix   # TLP, intel-undervolt
    ../../modules/nixos/services/tailscale.nix
  ];

  networking.hostName = "samsung-expert";
  # Form-factor hint used by power.nix to enable TLP
  custom.hardware.isNotebook = true;

  home-manager.users.frank = import ../../modules/home;

  system.stateVersion = "25.05";
}
```

---

## 6. Package Mapping (Arch → Nix)

| Arch / AUR Package | Nix Package / Method |
|---|---|
| `yay` / AUR | **Not needed** — use `pkgs` or `nix-env` with flakes |
| `reflector` | **Not needed** — nixpkgs has its own substituters |
| `pacman` | `nix` |
| `base-devel` | `pkgs.gcc pkgs.gnumake pkgs.binutils` |
| `mkinitcpio` | Handled by NixOS initrd config |
| `grub` + `grub-btrfs` | `boot.loader.grub.*` + grub-btrfs package |
| `snapper` + `snap-pac` | `services.snapper` (snap-pac hook equivalent via `boot.initrd`) |
| `tlp` + `tlp-rdw` | `services.tlp` |
| `intel-undervolt` | `services.undervolt` or `programs.intel-undervolt` |
| `iwd` | `networking.wireless.iwd` |
| `systemd-resolved` | `services.resolved` |
| `pipewire` + `wireplumber` | `services.pipewire` |
| `fail2ban` | `services.fail2ban` |
| `apparmor` | `security.apparmor` |
| `auditd` | `security.auditd` |
| `ufw` | `networking.firewall` (nftables) |
| `tailscale` | `services.tailscale` |
| `docker` + `docker-compose` | `virtualisation.docker` |
| `libvirt` + KVM | `virtualisation.libvirtd` |
| `fish` | `programs.fish.enable` (system) + home-manager |
| `neovim` | `programs.neovim` or home-manager |
| `git` | `programs.git` (home-manager) |
| `tmux` | `programs.tmux` (home-manager) |
| `btop` | `pkgs.btop` |
| `zoxide` | `programs.zoxide` (home-manager) |
| `fzf` | `programs.fzf` (home-manager) |
| `bat` | `pkgs.bat` |
| `ripgrep`, `fd` | `pkgs.ripgrep pkgs.fd` |
| `qutebrowser` | `pkgs.qutebrowser` |
| `mpv` | `programs.mpv` (home-manager) |
| `yt-dlp` | `pkgs.yt-dlp` |
| `zathura` | `programs.zathura` (home-manager) |
| `dunst` | `services.dunst` (home-manager) |
| `picom` | `services.picom` (home-manager) |
| `feh` | `pkgs.feh` |
| `flameshot` | `pkgs.flameshot` |
| `brightnessctl` | `pkgs.brightnessctl` |
| `autorandr` | `programs.autorandr` (home-manager) |
| `newsboat` | `programs.newsboat` (home-manager) |
| `anki` | `pkgs.anki-bin` |
| `calibre` | `pkgs.calibre` |
| `neomutt` | `programs.neomutt` (home-manager) |
| `msmtp` | `programs.msmtp` (home-manager) |
| `isync` (mbsync) | `programs.mbsync` (home-manager) |
| `aws-cli-v2` | `pkgs.awscli2` |
| `1password` | `programs._1password` + `programs._1password-gui` |
| `spotify-launcher` | `pkgs.spotify` |
| `insync` | `pkgs.insync` (unfree) |
| `drawio-desktop` | `pkgs.drawio` |
| `arc-gtk-theme` | `pkgs.arc-theme` |
| `qt5ct` | `qt.enable = true` in home-manager |
| `noto-fonts-*` | `fonts.packages = [ pkgs.noto-fonts pkgs.noto-fonts-cjk pkgs.noto-fonts-emoji ]` |
| `ttf-nerd-fonts-symbols` | `pkgs.nerdfonts` with subset |
| `ttf-joypixels` | `pkgs.joypixels` |
| `preload` | `services.preload.enable = true` |
| `rkhunter` | `pkgs.rkhunter` |
| `sysstat` | `pkgs.sysstat` |
| `ncdu` | `pkgs.ncdu` |
| `jq` | `pkgs.jq` |
| `tree` | `pkgs.tree` |
| `trash-cli` | `pkgs.trash-cli` |
| `bleachbit` | `pkgs.bleachbit` |
| `bc` | `pkgs.bc` |
| `tldr` | `pkgs.tldr` |
| `pre-commit` | `pkgs.pre-commit` |
| `git-delta` | `pkgs.delta` |
| `megasync-bin` (AUR) | `pkgs.megasync` or AppImage via `pkgs.appimageTools` |
| `btrfs-assistant` (AUR) | `pkgs.btrfs-assistant` |
| `noisetorch-bin` (AUR) | `pkgs.noisetorch` |
| `dashbinsh` (AUR) | `pkgs.dash` + symlink (`/bin/sh → dash`) |
| `advcpmv` (AUR) | Build from source in `pkgs/advcpmv/` |
| `xautolock` | `pkgs.xautolock` |
| `numlockx` | `pkgs.numlockx` |
| `unclutter` | `pkgs.unclutter` |
| `redshift` | `services.redshift` (home-manager) |
| `lxsession` | `pkgs.lxde.lxsession` (polkit agent) |
| `wol` | `pkgs.wol` |

---

## 7. Dotfiles Strategy

The current setup uses a bare git repo at `~/.config/dotfiles`. Two options in NixOS:

**Option A (Keep the bare repo):** Home Manager deploys a shell alias and sets
`$GIT_DIR`/`$GIT_WORK_TREE` as before. No change needed; dotfiles continue to work
exactly the same way.

**Option B (Full Home Manager):** Migrate dotfiles one-by-one into Home Manager
module configs. Gives you full reproducibility and allows `home-manager switch` to
apply everything declaratively. Recommended long-term but is a larger migration effort.

**Recommendation:** Start with Option A to unblock the OS migration, then
incrementally move dotfiles into Home Manager over time.

---

## 8. Secrets Migration (Ansible Vault → agenix)

### Step 1 — Generate host age keys
```bash
# On each machine (or from an existing SSH host key)
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key   # already done by nixos-install
# Convert to age pubkey:
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

### Step 2 — Generate personal age key
```bash
nix run nixpkgs#age -- -keygen -o ~/.config/sops/age/keys.txt
```

### Step 3 — Populate secrets.nix, then for each secret:
```bash
# Decrypt old ansible-vault secret:
ansible-vault decrypt --vault-password-file ~/ansi-vault-pass <encrypted-file> --output - \
  | agenix -e secrets/<name>.age
```

### Step 4 — Reference in NixOS modules:
```nix
age.secrets.tailscale-authkey = {
  file = ../../secrets/tailscale-authkey.age;
  owner = "root";
};
services.tailscale.authKeyFile = config.age.secrets.tailscale-authkey.path;
```

---

## 9. GRUB Configuration

```nix
# Mirrors roles/light_workstation/tasks/grub.yml
boot.loader.grub = {
  enable = true;
  device = "nodev";    # or "/dev/sdX" for legacy BIOS
  efiSupport = true;   # if using UEFI
  useOSProber = false;
  default = "saved";
  timeout = 1;
  gfxmodeEfi = "auto";
  extraPrepareConfig = ''
    GRUB_TERMINAL_OUTPUT="gfxterm"
  '';
  extraEntries = ''
    # grub-btrfs entries injected here by grub-btrfsd
  '';
};
# Kernel parameters (from roles/base/tasks/security.yml)
boot.kernelParams = [
  "lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
  "audit=1"
];
```

---

## 10. Migration Phases

### Phase 0 — Preparation (do before touching hardware)
- [ ] Set up the `nixos-config` git repository
- [ ] Write `flake.nix` with inputs pinned
- [ ] Extract all ansible-vault secrets and re-encrypt with agenix
- [ ] Commit dotfiles repo to GitHub (already done)
- [ ] Note current SSH host keys if you want persistence

### Phase 1 — Bootstrap a working NixOS install
- [ ] Boot NixOS installer ISO
- [ ] Partition disks (matching current btrfs subvolume layout if possible)
- [ ] Run `nixos-generate-config` → commit output to `hosts/workstation/hardware-configuration.nix`
- [ ] Write minimal `hosts/workstation/default.nix` (base + ssh + network only)
- [ ] `nixos-install` and reboot into a working system with SSH access

### Phase 2 — System modules
- [ ] `modules/nixos/base/` — users, locale, packages, ssh, security, firewall, network
- [ ] `modules/nixos/hardware/btrfs.nix` — snapper, grub-btrfs
- [ ] `modules/nixos/desktop/` — xorg, audio, bluetooth, fonts, autorandr
- [ ] `modules/nixos/services/tailscale.nix`, docker.nix, preload.nix
- [ ] Hardware-specific: intel.nix or nvidia.nix

### Phase 3 — Home Manager (user environment)
- [ ] `modules/home/shell/` — fish, tmux
- [ ] `modules/home/programs/` — neovim, git, zathura, mpv, qutebrowser, lf, newsboat…
- [ ] `modules/home/desktop/` — dwm (custom build), st, dmenu, slock, picom, dunst, feh
- [ ] `modules/home/services/` — redshift, rclone, syncthing

### Phase 4 — Suckless custom builds
- [ ] Write `pkgs/dwm/laptop.nix` pointing to your github branch
- [ ] Same for st, dmenu, slock, dwmblocks
- [ ] Integrate into home manager packages list
- [ ] Verify builds succeed with `nix build .#packages.x86_64-linux.dwm-laptop`

### Phase 5 — Work configuration
- [ ] `modules/home/work/` — neomutt, aws, datagrip, cursor, onepassword, slack
- [ ] Decrypt and re-encrypt all work secrets to agenix
- [ ] Verify email send/receive works (msmtp, mbsync)
- [ ] Verify AWS CLI, DataGrip, 1Password function

### Phase 6 — Samsung Expert Book
- [ ] Run `nixos-generate-config` on the laptop
- [ ] Write `hosts/samsung-expert/default.nix` (base + intel + power + tailscale)
- [ ] Test TLP + intel-undervolt + WiFi (iwd)
- [ ] Verify battery life is comparable to Arch

### Phase 7 — Hardening and cleanup
- [ ] Verify apparmor profiles load correctly
- [ ] Verify auditd produces expected logs
- [ ] Verify fail2ban triggers on SSH brute force
- [ ] Run `nixos-rebuild build` from a clean state to confirm reproducibility
- [ ] Clean up any `environment.systemPackages` one-offs into proper modules

---

## 11. Key Differences from Arch (Things to Unlearn)

| Arch / Ansible concept | NixOS equivalent |
|---|---|
| `pacman -S package` | Add to `environment.systemPackages` or home-manager `home.packages` |
| AUR / `yay` | `pkgs.callPackage` for custom derivations; many AUR pkgs are in nixpkgs already |
| `/etc/pacman.d/hooks/` | `system.activationScripts` or NixOS module hooks |
| `systemctl enable service` | `services.<name>.enable = true` |
| `chsh -s /usr/bin/fish` | `users.users.frank.shell = pkgs.fish` |
| Editing `/etc/ssh/sshd_config` | `services.openssh.settings.*` |
| `mkinitcpio` | `boot.initrd.*` options |
| `reflector` mirror selection | Not needed; nixpkgs has CDN substituters |
| `snapper createconfig /` | `services.snapper.configs.root = { ... }` |
| Rolling updates (`pacman -Syu`) | `nix flake update && nixos-rebuild switch` |
| Rollbacks via snapper | `nixos-rebuild --rollback` or boot menu (every generation is bootable) |
| dotfile symlinks via stow/bare git | `home.file` in Home Manager OR keep bare repo (Option A) |

---

## 12. Useful Tools and Resources

- **disko** — declarative disk partitioning: `github.com/nix-community/disko`
- **nixos-hardware** — hardware quirks database: `github.com/NixOS/nixos-hardware`
- **agenix** — secret management: `github.com/ryantm/agenix`
- **home-manager** manual: `nix-community.github.io/home-manager/`
- **mynixos.com** — searchable NixOS options explorer
- **search.nixos.org/packages** — package search (check before writing custom derivations)
- **nix-index** — `nix-locate` equivalent of `pkgfile`
- **comma** (`,`) — run any nix package without installing: `github.com/nix-community/comma`
- **nh** — better `nixos-rebuild` wrapper with diff output: `github.com/viperML/nh`

---

*Generated 2026-04-08 — based on full audit of `/home/frank/projects/ansible/main-ansible`*
