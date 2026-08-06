# feh — image viewer and wallpaper setter
{ pkgs, ... }:
{
  home.packages = [ pkgs.feh ];

  # Set wallpaper via feh on X11 startup.
  # The actual wallpaper file path comes from the dotfiles repo / home dir.
  # This activation script mirrors the `feh --bg-scale` call in .xinitrc.
  # If the dotfiles bare repo manages .xinitrc, this is redundant — keep it
  # commented until .xinitrc is migrated into Home Manager.

  # xsession.initExtra = ''
  #   feh --no-fehbg --bg-scale "$HOME/.config/wallpaper.jpg" &
  # '';
}
