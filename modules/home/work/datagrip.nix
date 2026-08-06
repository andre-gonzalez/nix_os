# DataGrip IDE (JetBrains database tool)
# AUR: datagrip + datagrip-jre on Arch
{ pkgs, ... }:
{
  home.packages = [ pkgs.jetbrains.datagrip ];
}
