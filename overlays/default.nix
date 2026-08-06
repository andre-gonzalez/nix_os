# Overlays — pin AUR-equivalent packages to nixpkgs-unstable
# or override specific packages where needed.
#
# Usage in flake.nix:
#   nixpkgs.overlays = [ (import ./overlays) ];
#
# Each overlay follows the pattern:
#   final: prev: { packageName = ...; }

final: prev: {
  # Example: prefer unstable claude-code over stable
  # claude-code = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.claude-code;

  # dash as /bin/sh replacement (AUR: dashbinsh on Arch)
  # The NixOS option `environment.binsh = "${pkgs.dash}/bin/dash"` handles this
  # more cleanly than an overlay.

  # spotify-launcher → spotify (nixpkgs ships spotify directly)
  spotify-launcher = prev.spotify;

  # advcpmv — cp/mv with progress bars (AUR: advcpmv)
  # advcpmv = final.callPackage ../pkgs/advcpmv { };
}
