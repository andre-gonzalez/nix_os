# Remaining packages from roles/work/tasks/packages.yml. claude-code comes in
# with crash-notify (home/desktop/crash-notify.nix). Not ported: insomnia,
# terraform and python311 (roles not included in Ansible, absent on Arch).
{ pkgs, ... }:
{
  home.packages = [ pkgs.drawio ];
}
