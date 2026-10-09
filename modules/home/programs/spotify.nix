# Spotify — mirrors roles/light_workstation/tasks/spotify.yml and the
# spotify-launcher entry in packages.yml: the official client, plus
# spotify-player for the terminal.
#
# spotify-player's ~/.config/spotify-player/app.toml comes from the dotfiles
# repo (Ansible's vaulted copy of it is older and no longer needed).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    spotify
    spotify-player
  ];
}
