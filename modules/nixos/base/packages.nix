# Mirrors packages installed across roles/base and roles/light_workstation
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Core tools
    git
    delta          # was git-delta (renamed to delta in nixpkgs)
    btop
    htop
    wget
    curl
    unzip
    p7zip
    tree
    bc
    jq
    man-db

    # Search / navigation
    ripgrep
    fd
    fzf
    zoxide
    bat
    ncdu

    # System utilities
    usbutils
    pciutils
    lshw
    sysstat
    # rkhunter removed from nixpkgs (see security.nix note)
    inetutils
    wol
    ntfs3g
    nfs-utils
    trash-cli
    bleachbit
    tldr
    pre-commit

    # Networking
    nethogs
    tcpdump
    iw
    wirelesstools

    # Development
    gnumake
    gcc
    binutils
    python3
    python3Packages.pip
    python3Packages.pipx
    yamllint
    ansible

    # AWS
    awscli2

    # Shell helpers
    fish
    tmux
    neovim

    # Clipboard / X utilities (available system-wide)
    xclip
  ];

  # Set neovim as default editor
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Allow unfree packages (1password, spotify, etc.)
  nixpkgs.config.allowUnfree = true;
  # JoyPixels ships under a non-free license that must be accepted explicitly.
  nixpkgs.config.joypixels.acceptLicense = true;
}
