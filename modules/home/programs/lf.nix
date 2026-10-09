# lf file manager. Config (~/.config/lf/lfrc) is managed by the bare dotfiles
# repo, so home-manager only installs lf and the preview tools (no programs.lf).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lf
    ueberzugpp # image previews through ~/.scripts/lfub (lfrc, scope)
    sxiv       # lfrc opens images with it
    bat
    chafa
    ffmpegthumbnailer
    file
    trash-cli
  ];
}
