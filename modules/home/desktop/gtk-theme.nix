# GTK theme — what the Arch machines actually run (catppuccin-gtk-theme-mocha,
# accent teal), not the arc-gtk-theme listed in Ansible's AUR packages.
#
# The theme is *selected* by ~/.config/gtk-3.0/settings.ini in the dotfiles
# repo, so home-manager only installs it (no gtk.enable, which would generate
# that file). settings.ini names the Arch package's directory,
# "catppuccin-mocha-teal-standard+default"; nixpkgs builds the same theme
# without the "+default" tweak suffix, so an alias with the Arch name is added
# and the dotfiles stay identical on both systems.
#
# Qt is left alone: qt5ct was installed on Arch, but QT_QPA_PLATFORMTHEME was
# never set, so it never applied.
{ pkgs, ... }:
let
  catppuccin = pkgs.catppuccin-gtk.override {
    accents = [ "teal" ];
    variant = "mocha";
    size = "standard";
  };
  theme = pkgs.symlinkJoin {
    name = "catppuccin-gtk-mocha-teal";
    paths = [ catppuccin ];
    postBuild = ''
      ln -s catppuccin-mocha-teal-standard \
        "$out/share/themes/catppuccin-mocha-teal-standard+default"
    '';
  };
in
{
  home.packages = [ theme ];
}
