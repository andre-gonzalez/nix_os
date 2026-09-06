# stw — suckless text in window (on-screen display)
{ stdenv, lib, libx11, libxft }:
stdenv.mkDerivation {
  pname = "stw";
  version = "unstable";

  src = builtins.fetchGit {
    url = "git@github.com:andre-gonzalez/stw.git";
    ref = "main";
    # rev = "abc123...";
  };

  buildInputs = [ libx11 libxft ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "suckless text in window — OSD utility";
    homepage    = "https://github.com/andre-gonzalez/stw";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
