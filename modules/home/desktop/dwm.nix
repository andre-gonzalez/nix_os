# Custom dwm build from andre-gonzalez's private git branches
# pkgs/dwm/ contains the derivations; this module wires the right variant
# into the user's PATH and sets up .xinitrc to launch it.
{ customPkgs, pkgs, lib, ... }:
{
  home.packages = [
    # Include both builds; the correct one is chosen by the .xinitrc / autorandr hook
    customPkgs.dwm-laptop
    customPkgs.dwm-ultrawide
  ];

  # .xinitrc — launches dwmblocks + dwm (keep in sync with dotfiles repo)
  # When dotfiles are fully migrated to Home Manager this file can move here.
  # For now: Option A (bare dotfiles repo manages .xinitrc).
}
