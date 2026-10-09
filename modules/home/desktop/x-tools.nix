# Small X tools from roles/light_workstation:
#   stw         — tasks/stw.yml; ~/.scripts/show_keybinds.sh draws with it
#   wall-d      — tasks/wall-d.yml; interactive wallpaper manager
#   sent        — suckless presentations (AUR sent-git), with farbfeld for images
#   something-x — Nothing earbuds manager (AUR); pkgs/something-x
{ pkgs, customPkgs, ... }:
{
  home.packages = [
    customPkgs.stw
    customPkgs.wall-d
    customPkgs.something-x
    pkgs.sent
    pkgs.farbfeld
  ];
}
