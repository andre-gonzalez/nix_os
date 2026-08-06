# tmux + tmuxp
# tmux config (~/.config/tmux/tmux.conf) is managed by the bare dotfiles repo,
# so home-manager only installs the binaries (no programs.tmux config).
{ pkgs, ... }:
{
  home.packages = [ pkgs.tmux pkgs.tmuxp ];
}
