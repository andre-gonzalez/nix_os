# picom compositor
# Config (~/.config/picom/picom.conf) is managed by the bare dotfiles repo and
# picom is launched from that repo's .xinitrc, so home-manager only installs the
# binary (no services.picom, which would generate the config and a user service).
{ pkgs, ... }:
{
  home.packages = [ pkgs.picom ];
}
