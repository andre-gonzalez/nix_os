# Redshift — color temperature / blue light filter
# Config (~/.config/redshift/redshift.conf) is managed by the bare dotfiles repo
# and redshift is launched from that repo's .xinitrc, so home-manager only
# installs the binary (no services.redshift, which would generate the config
# and a user service).
{ pkgs, ... }:
{
  home.packages = [ pkgs.redshift ];
}
