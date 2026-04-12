# picom compositor — mirrors roles/light_workstation
{ ... }:
{
  services.picom = {
    enable = true;
    backend = "glx";

    # Shadows
    shadow = true;
    shadowOffsets = [ (-7) (-7) ];
    shadowOpacity = 0.7;
    shadowExclude = [
      "name = 'Notification'"
      "class_g = 'Conky'"
      "_GTK_FRAME_EXTENTS@:c"
    ];

    # Fading
    fade = true;
    fadeSteps = [ 0.03 0.03 ];

    # Opacity
    activeOpacity = 1.0;
    inactiveOpacity = 0.9;
    menuOpacity = 1.0;
    opacityRules = [
      "100:class_g = 'dwm'"
      "100:name = 'dwmblocks'"
    ];

    # VSync
    vSync = true;

    settings = {
      # Rounded corners (picom >= 8)
      corner-radius = 4;
    };
  };
}
