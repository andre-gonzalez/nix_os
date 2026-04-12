# xbindkeys — key bindings outside of dwm's key handler
{ pkgs, ... }:
{
  home.packages = [ pkgs.xbindkeys ];

  # Configuration file mirrors ~/.xbindkeysrc from dotfiles repo.
  # Uncomment and populate once dotfiles are migrated to Home Manager.
  # home.file.".xbindkeysrc".text = ''
  #   # Volume control
  #   "pamixer --increase 5"
  #     XF86AudioRaiseVolume
  #   "pamixer --decrease 5"
  #     XF86AudioLowerVolume
  #   "pamixer --toggle-mute"
  #     XF86AudioMute
  #   # Brightness
  #   "brightnessctl set +10%"
  #     XF86MonBrightnessUp
  #   "brightnessctl set 10%-"
  #     XF86MonBrightnessDown
  #   # Screenshot
  #   "flameshot gui"
  #     Print
  # '';
}
