# Ente Auth (2FA codes) — mirrors roles/light_workstation/tasks/ente-auth.yml.
# It keeps its key in the Secret Service, which gnome-keyring provides
# (nixos/desktop/keyring.nix).
{ pkgs, ... }:
{
  home.packages = [ pkgs.ente-auth ];
}
