# Workstation packages from roles/light_workstation that a server does not
# need. The shared core is in ../base/packages.nix.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # System utilities
    wol
    ntfs3g
    trash-cli
    bleachbit
    tldr
    pre-commit

    # Networking
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

    # Clipboard / X utilities (available system-wide)
    xclip
  ];

  # JoyPixels ships under a non-free license that must be accepted explicitly.
  nixpkgs.config.joypixels.acceptLicense = true;
}
