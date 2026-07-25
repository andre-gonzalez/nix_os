# dunst notification daemon. Config (~/.config/dunst/dunstrc) is managed by the
# bare dotfiles repo; dunst is D-Bus activated, so home-manager only installs the
# package (no services.dunst, which would generate the config + a user service).
{ pkgs, ... }:
{
  home.packages = [ pkgs.dunst ];
}
