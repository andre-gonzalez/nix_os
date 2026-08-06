# Custom dwm build from andre-gonzalez's dwm repo (single `main` branch).
# pkgs/dwm/ contains the derivation; this module puts it on the user's PATH.
{ customPkgs, pkgs, lib, ... }:
{
  # One binary for every screen — the ultra-wide layout is picked at runtime
  # from the monitor width, so no per-host variant or autorandr hook is needed.
  home.packages = [ customPkgs.dwm ];

  # .xinitrc — launches dwmblocks + dwm (keep in sync with dotfiles repo)
  # When dotfiles are fully migrated to Home Manager this file can move here.
  # For now: Option A (bare dotfiles repo manages .xinitrc).
}
