# dwmstatus — status string generator (alternative to dwmblocks)
{ stdenv, lib, xorg }:
stdenv.mkDerivation {
  pname = "dwmstatus";
  version = "unstable";

  src = builtins.fetchGit {
    url = "git@github.com:andre-gonzalez/dwmstatus.git";
    ref = "main";
    # rev = "abc123...";
  };

  buildInputs = [ xorg.libX11 ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "status string generator for dwm";
    homepage    = "https://github.com/andre-gonzalez/dwmstatus";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
