# Work-profile fonts (ttf-ibm-plex on Arch)
{ pkgs, ... }:
{
  home.packages = [ pkgs.ibm-plex ];

  fonts.fontconfig.enable = true;
}
