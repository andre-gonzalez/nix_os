# Insync (Google Drive sync) — mirrors roles/heavy_workstation/tasks/Insync.yml.
# Started by .xinitrc in the dotfiles (`insync start &`), so only the package
# is needed here.
{ pkgs, ... }:
{
  home.packages = [ pkgs.insync ];
}
