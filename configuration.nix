# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    timeout = 1;
  };

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking = {
    hostName = "nixos"; # Define your hostname.
    networkmanager.enable = true;  # Easiest to use and most distros use this by default.
    wireless.enable = false;
    # nameservers = ["1.1.1.1" "1.0.0.1"]
  };

  # Set your time zone.
  time.timeZone = "America/Mexico_City";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "pt_BR.UTF-8";
  console = {
     font = "Lat2-Terminus16";
     keyMap = "dvorak";
    # useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "dvorak-intl";
  services.xserver.xkb.options = "caps:swapescape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable fish shell
  programs.fish.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.frank = {
    isNormalUser = true;
    home = "/home/frank/";
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.fish; # Set default user shell to fish
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsYIPZvhFhETD4PfqryP/yVpVpRW0bYsrwvPxj5uz/R"];
    packages = with pkgs; [
      firefox
      tree
      fish
      bat
    ];
  };

  # Disable root login
  users.users.root.hashedPassword = "!";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     cron
     ansible
     fail2ban
     pam_tmpdir
     chkrootkit
     passwdqc
     aide
     sysstat
     git
     tailscale
     # btrfs-assistant
     # btrfs-auto-snapshot
     # timeshift
     fastfetch
     xorg.xinit
     st
     dmenu
     tmux
     tmuxp
     xautolock
     xbindkeys
     arandr
     numlockx
     feh
     unclutter
     xclip
     brightnessctl
     ripgrep
     fzf
     lxsession # polkit agent to fill password when launching applications with my run launcher
     flameshot
     bat
     dunst
     qt5ct # To set theme for qt applications
     csvkit
     yamllint
     ansible-lint
     nodejs_22 # Necessary to install gramarly language server in neovim play
     qutebrowser
     unzip
     mpv # Terminal based video player
     yt-dlp # Download youtube videos, necessary to play youtube videos on mpv
     pre-commit # To use with git to ensure format and linting before commits
     xorg.xinput
     pipenv
     gnumake
     util-linux
     liberation_ttf
     fd
     libnotify
     pamixer
     nerdfonts
     joypixels
     libertine
     arc-theme
     clipmenu
     noto-fonts
     bleachbit
     awscli
     python312Packages.debugpy
     spotify
     trash-cli
     nethogs
     man-db
     tldr
     zoxide
     wol
     redshift
     inetutils
     ntfs3g
     newsboat
     python312Packages.adblock
     libreoffice-qt6-still
     noto-fonts-color-emoji
     ncdu
     delta
     brave
     dwmblocks
     dwm-status
     slock
     stw
     anki-bin
     rsync
     iwd
     zathura
     obsidian
     sent
     farbfeld
     lf
     preload
     timeshift
     tlp
     smartmontools
     ethtool
     powertop
     docker
     docker-compose
     dbeaver-bin
     qutebrowser
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
     enable = true;
     ports = [1050];
     settings.PermitRootLogin = "no";
     settings.PasswordAuthentication = false;
     settings.ClientAliveCountMax = 2;
     settings.TCPKeepAlive = "no";
     settings.LogLevel = "VERBOSE";
     settings.AllowUsers = ["frank"];
     settings.PermitEmptyPasswords = "no";
     settings.MaxAuthTries = 3;
     settings.X11Forwarding = false;
     settings.MaxSessions = 2;
     settings.AllowTcpForwarding = "no";
     settings.AllowAgentForwarding = "no";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

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
  system.stateVersion = "24.05"; # Did you read the comment?

  # Nvidia proprietary drivers
  # services.xserver.videoDrivers = [ "nvidia" ];

  # Make QT applications look similar to GTK ones
  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style = "gtk2";

  # Configure cron
  services.cron = {
    enable = true;
    # systemCronJobs = [
    # ];
  };

  # Configure fail2ban
  services.fail2ban = {
    enable = false;
    ignoreIP = ["127.0.0.1/8"];
    bantime = "3600";
    jails = {
      findtime = "600";
    };
    maxretry = 5;
  };

  # Disable core dumps
  systemd.coredump.enable = false;

  # Set umask to 027
  environment.extraInit = "umask 027";

  # Enable sysstat
  services.sysstat.enable = true;

  # Enable tailscale
  services.tailscale.enable = true;

  # Set neovim as default editor
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  # Configure git THIS CONFIGURATION SHOULD BE MOVED TO HOME MANAGER https://nixos.wiki/wiki/Home_Manager
  # programs.git = {
  #   enable = true;
  #   userName = "André Gonzalez";
  #   userEmail = "lopescg@gmail.com";
    # aliases = {
    #   ga = "add";
    #   gc = "commit";
    #   gp = "push";
    #   gs = "status";
    # };
  # };

  # Configure home manager to create directories

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable dwm
  services.xserver.windowManager.dwm.enable = true;
  services.xserver.windowManager.dwm.package = pkgs.dwm.overrideAttrs {
    src = /home/frank/.config/dwm;
  };

  # Accept joypixels license
  nixpkgs.config.joypixels.acceptLicense = true;

}
