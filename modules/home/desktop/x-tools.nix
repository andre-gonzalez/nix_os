# Small X tools with their own Ansible tasks in roles/light_workstation:
#   stw    — tasks/stw.yml; ~/.scripts/show_keybinds.sh draws with it
#   wall-d — tasks/wall-d.yml; interactive wallpaper manager
{ customPkgs, ... }:
{
  home.packages = [
    customPkgs.stw
    customPkgs.wall-d
  ];
}
