# git. Config (~/.config/git/config) is managed by the bare dotfiles repo, so
# home-manager only installs git and the delta pager (no programs.git).
{ pkgs, ... }:
{
  home.packages = with pkgs; [ git delta ];
}
