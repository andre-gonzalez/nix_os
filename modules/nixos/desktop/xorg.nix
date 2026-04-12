# Mirrors roles/light_workstation — xorg, startx, autologin to tty1
{ pkgs, ... }:
{
  services.xserver = {
    enable = true;

    # Dvorak keyboard layout in X11 (mirrors setxkbmap in .xinitrc)
    xkb = {
      layout = "us";
      variant = "dvorak";
      options = "caps:escape"; # caps lock → escape (common for vim users)
    };

    # No display manager — frank runs startx from tty1
    displayManager.startx.enable = true;

    # We use a custom dwm build from pkgs/, not the nixpkgs dwm package
    windowManager.dwm.enable = false;
  };

  # Autologin frank on tty1 (mirrors getty override.conf)
  services.getty.autologinUser = "frank";

  # Polkit agent for GUI privilege elevation
  environment.systemPackages = with pkgs; [
    lxde.lxsession
    xorg.xsetroot
    xorg.xrandr
    xorg.xinput
    xorg.xwininfo
    xorg.xdpyinfo
    arandr
    numlockx
    unclutter
    xclip
    xautolock
    flameshot
    brightnessctl
  ];
}
