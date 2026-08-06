# Exports all custom package derivations.
# Usage: import ./pkgs { inherit pkgs; lib = nixpkgs.lib; }
{ pkgs, lib }:
{
  dwm-laptop    = pkgs.callPackage ./dwm/laptop.nix     {};
  dwm-ultrawide = pkgs.callPackage ./dwm/ultrawide.nix  {};
  st            = pkgs.callPackage ./st/default.nix      {};
  dmenu         = pkgs.callPackage ./dmenu/default.nix   {};
  slock         = pkgs.callPackage ./slock/default.nix   {};
  dwmblocks     = pkgs.callPackage ./dwmblocks/default.nix {};
  dwmstatus     = pkgs.callPackage ./dwmstatus/default.nix {};
  wall-d        = pkgs.callPackage ./wall-d/default.nix  {};
  notas         = pkgs.callPackage ./notas/default.nix   {};
  stw           = pkgs.callPackage ./stw/default.nix     {};
}
