# dwm — laptop-dwm branch from andre-gonzalez's private repo
# config.h patches live in the git branch; no patching needed here.
{ stdenv, lib, fetchgit, xorg, libX11, libXft, libXinerama }:
stdenv.mkDerivation {
  pname = "dwm-laptop";
  version = "unstable";

  src = builtins.fetchGit {
    url = "https://github.com/andre-gonzalez/dwm.git";
    ref = "main";
    # Pinned for reproducible pure eval. Update by bumping this rev.
    rev = "976b60423b8f93952f3570dc13cccd1d4d2da4dc";
  };

  buildInputs = [ xorg.libX11 xorg.libXft xorg.libXinerama ];

  makeFlags = [ "PREFIX=$(out)" ];

  installPhase = ''
    mkdir -p $out/bin $out/share/man/man1
    cp dwm $out/bin/dwm-laptop
    cp dwm.1 $out/share/man/man1/dwm.1 2>/dev/null || true
  '';

  meta = {
    description = "suckless dynamic window manager — laptop branch";
    homepage    = "https://github.com/andre-gonzalez/dwm";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
