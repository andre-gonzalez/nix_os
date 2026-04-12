# dwmblocks — modular status bar for dwm
{ stdenv, lib, xorg }:
stdenv.mkDerivation {
  pname = "dwmblocks";
  version = "unstable";

  src = builtins.fetchGit {
    url = "git@github.com:andre-gonzalez/dwmblocks.git";
    ref = "main";
    # rev = "abc123...";
  };

  buildInputs = [ xorg.libX11 ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "modular status bar for dwm";
    homepage    = "https://github.com/andre-gonzalez/dwmblocks";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
