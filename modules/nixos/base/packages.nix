# Mirrors packages installed across roles/base and roles/light_workstation.
# Only what a headless server needs too; desktop, dev and work tools are in
# ../workstation/packages.nix.
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
    # rkhunter removed from nixpkgs (see security.nix note)
    inetutils
    nfs-utils

    # Networking
    nethogs
    tcpdump

    # Shell helpers
    fish
    tmux
    neovim
  ];

  # Set neovim as default editor
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # dash as /bin/sh — mirrors the AUR `dashbinsh` package on Arch. ~/.scripts
  # and the dotfiles' sh scripts were written and run against dash there.
  environment.binsh = "${pkgs.dash}/bin/dash";

  # Allow unfree packages (1password, spotify, etc.)
  nixpkgs.config.allowUnfree = true;
}
