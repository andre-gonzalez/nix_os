# Qutebrowser with Python ad-block
# Config (~/.config/qutebrowser/config.py) is managed by the bare dotfiles repo,
# so home-manager only installs the browser (no programs.qutebrowser config).
# The nixpkgs qutebrowser already bundles the `adblock` python module, so the
# python-adblock backend works out of the box.
{ pkgs, ... }:
{
  home.packages = [ pkgs.qutebrowser ];
}
