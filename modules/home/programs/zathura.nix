# Zathura PDF viewer — set as XDG default for PDF in home/default.nix
# Config (~/.config/zathura/zathurarc) is managed by the bare dotfiles repo, so
# home-manager only installs the binary (no programs.zathura config).
{ pkgs, ... }:
{
  home.packages = [ pkgs.zathura ];
}
