# Newsboat RSS reader
# Config (~/.config/newsboat/{config,urls}) is managed by the bare dotfiles
# repo, so home-manager only installs the binary (no programs.newsboat config).
{ pkgs, ... }:
{
  home.packages = [ pkgs.newsboat ];
}
