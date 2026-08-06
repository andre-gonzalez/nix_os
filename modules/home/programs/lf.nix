# lf file manager. Config (~/.config/lf/lfrc) is managed by the bare dotfiles
# repo, so home-manager only installs lf and the preview tools (no programs.lf).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lf
    bat
    chafa
    ffmpegthumbnailer
    file
    trash-cli
  ];
}
