# dwm — ultra-wide-dwm branch from andre-gonzalez's private repo
{ stdenv, lib, fetchgit, xorg }:
stdenv.mkDerivation {
  pname = "dwm-ultrawide";
  version = "unstable";

  src = builtins.fetchGit {
    url = "https://github.com/andre-gonzalez/dwm.git";
    ref = "ultra-wide-dwm";
    rev = "423518f4ef3845684b3182abb9da3a1c0895dca9";
  };

  buildInputs = with xorg; [ libX11 libXft libXinerama ];

  makeFlags = [ "PREFIX=$(out)" ];

  installPhase = ''
    mkdir -p $out/bin $out/share/man/man1
    cp dwm $out/bin/dwm-ultrawide
    cp dwm.1 $out/share/man/man1/dwm-ultrawide.1 2>/dev/null || true
  '';

  meta = {
    description = "suckless dynamic window manager — ultra-wide branch";
    homepage    = "https://github.com/andre-gonzalez/dwm";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
