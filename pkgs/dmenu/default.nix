# dmenu — dynamic menu from andre-gonzalez's private repo
{ stdenv, lib, xorg }:
stdenv.mkDerivation {
  pname = "dmenu";
  version = "unstable";

  src = builtins.fetchGit {
    url = "https://github.com/andre-gonzalez/dmenu.git";
    ref = "main";
    rev = "658e69fc7a5f4b8163afa7b056895963e2e6d380";
  };

  buildInputs = with xorg; [ libX11 libXft libXinerama ];

  makeFlags = [ "PREFIX=$(out)" ];
  preBuild = "make clean"; # upstream commits a prebuilt generic-Linux binary; force a real recompile

  meta = {
    description = "suckless dynamic menu — customised build";
    homepage    = "https://github.com/andre-gonzalez/dmenu";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
