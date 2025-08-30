# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];


  boot.loader.grub = {
	efiSupport = true;
    timeout = 1;
  };


  networking = {
    hostName = "nixos-vm";
    networkmanager.enable = true;
    wireless.enable = false;
    # networkmanager.wifi.backend = "iwd";
    # nameservers = ["1.1.1.1" "1.0.0.1"]

    firewall.enable = false;
    # firewall.allowedTCPPorts = [ 22 ];
    # firewall.allowedUDPPorts = [ ... ];

  };


  time.timeZone = "America/Mexico_City";


  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "dvorak";
    # useXkbConfig = true; # use xkb.options in tty.
  };


  services = {

    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    # Enable CUPS to print documents.
    # printing.enable = true;

    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "dvorak-intl";
      xkb.options = "caps:swapescape";
      displayManager.startx.enable = true;

      windowManager.dwm.enable = true;
      windowManager.dwm.package = pkgs.dwm.overrideAttrs {
        src = /home/frank/.config/dwm/laptop-dwm;
      };
    };

    # Nvidia proprietary drivers
    # videoDrivers = [ "nvidia" ];

    # Enable touchpad support (enabled default in most desktopManager).
    libinput.enable = true;

    openssh = {
      enable = true;
      ports = [ 1050 ];
      settings.PermitRootLogin = "no";
      settings.PasswordAuthentication = false;
      settings.ClientAliveCountMax = 2;
      settings.TCPKeepAlive = "no";
      settings.LogLevel = "VERBOSE";
      settings.AllowUsers = [ "frank" ];
      settings.PermitEmptyPasswords = "no";
      settings.MaxAuthTries = 3;
      settings.X11Forwarding = false;
      settings.MaxSessions = 2;
      settings.AllowTcpForwarding = "no";
      settings.AllowAgentForwarding = "no";
    };

    cron = {
      enable = true;
      # systemCronJobs = [
      # ];
    };

    fail2ban = {
      enable = false;
      ignoreIP = [ "127.0.0.1/8" ];
      bantime = "3600";
      jails = {
        findtime = "600";
      };
      maxretry = 5;
    };

    sysstat.enable = true;

    tailscale.enable = true;
  };


  programs = {
    fish.enable = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # mtr.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    slock.enable = true;

  };


  users.users = {

    # Disable root login
    root.hashedPassword = "!";

    frank = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsYIPZvhFhETD4PfqryP/yVpVpRW0bYsrwvPxj5uz/R" ];
      packages = with pkgs; [
        firefox
        fish
      ];
    };
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {

    extraInit = "umask 027";

    systemPackages = with pkgs; [
      # Base packages
      # aide
      # chkrootkit
      cron
      # ethtool
      fail2ban
      git
      # inetutils
      # iwd
      libgcc
      # man-db
      neovim
      # nethogs
      # ntfs3g
      # pam_tmpdir
      # passwdqc
      # rsync
      # smartmontools
      sysstat
      # tldr
      # trash-cli
      unzip
      util-linux

      # Packages to develop on nix files
      home-manager
      nil
      nixpkgs-fmt

      # Develop Packages
      ansible
      # ansible-lint
      bat
      # csvkit
      # dbeaver-bin
      # delta
      # docker
      # docker-compose
      # fd
      fzf
      # lf
      # pipenv
      # pre-commit
      # python312Packages.debugpy
      ripgrep
      tailscale
      tmux
      tmuxp
      # tree
      # yamllint
      # zoxide

      # Random Packages
      fastfetch

      # BTRFS Packages
      # btrfs-assistant
      # btrfs-auto-snapshot
      # timeshift

      # Graphical environment
      arandr
      arc-theme
      brightnessctl
      clipmenu
      # dunst
      dwm-status
      feh
      # flameshot
      # lxsession # polkit agent to fill password when launching applications with my run launcher
      numlockx
      pamixer
      # qt5ct # To set theme for qt applications
      redshift
      slock
      stw
      # unclutter
      xautolock
      xbindkeys
      xclip
      # xcompmgr
      xorg.xinit
      (st.overrideAttrs (oldAttrs: rec {
        patches = [
          (fetchpatch {
            url = "https://st.suckless.org/patches/alpha/st-alpha-20220206-0.8.5.diff";
            sha256 = "10gvwnpbjw49212k25pddji08f4flal0g9rkwpvkay56w8y81r22";
          })
        ];
        # configFile = writeText "config.def.h" (builtins.readFile /home/frank/.config/st/config.h);
        configFile = writeText "config.def.h" (builtins.readFile "${builtins.fetchTarball {
        url =  "https://github.com/andre-gonzalez/st/archive/main.tar.gz";
        }}/config.h");
        postPatch = "${oldAttrs.postPatch}\n cp ${configFile} config.def.h";
      }))
      (dmenu.overrideAttrs (oldAttrs: rec {
        src = builtins.fetchTarball {
          url = "https://github.com/andre-gonzalez/dmenu/archive/main.tar.gz";
        };
      }))
      (dwmblocks.overrideAttrs (oldAttrs: rec {
        # configFile = writeText "config.def.h" (builtins.readFile /home/frank/.config/dwmblocks/config.h);
        configFile = writeText "config.def.h" (builtins.readFile "${builtins.fetchTarball {
url = "https://github.com/andre-gonzalez/dwmblocks/archive/main.tar.gz";
}}/config.h");
        postPatch = "${oldAttrs.postPatch}\n cp ${configFile} config.def.h";
      }))

      # Fonts
      # joypixels
      # libertine
      # nerdfonts
      # noto-fonts
      # noto-fonts-color-emoji

      # Web Browser
      # brave
      # qutebrowser

      # Workstation
      # bleachbit
      # farbfeld
      # libreoffice-qt6-still
      # mpv
      # ncdu
      # newsboat
      # obsidian
      # preload
      # python312Packages.adblock
      # sent
      # spotify
      # yt-dlp
      # zathura

      # Laptop
      # powertop
      # tlp

    ];

  };


  system = {
    # Copy the NixOS configuration file and link it from the resulting system
    # (/run/current-system/configuration.nix). This is useful in case you
    # accidentally delete configuration.nix.
    copySystemConfiguration = true;
    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
    # to actually do that.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    stateVersion = "24.05"; # Did you read the comment?
  };


  qt = {
    enable = true;
    # Make QT applications look similar to GTK ones
    platformTheme = "gtk2";
    style = "gtk2";
  };


  nixpkgs.config = {

    # Allow unfree packages
    allowUnfree = true;

    joypixels.acceptLicense = true;

  };


  # Disable core dumps
  systemd.coredump.enable = false;

  nix.settings.allowed-users = [ "frank" ];

}
