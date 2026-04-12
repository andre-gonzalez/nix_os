# dmenu — dynamic menu from andre-gonzalez's private repo
{ stdenv, lib, xorg }:
stdenv.mkDerivation {
  pname = "dmenu";
  version = "unstable";

  src = builtins.fetchGit {
    url = "git@github.com:andre-gonzalez/dmenu.git";
    ref = "main";
    # rev = "abc123...";
  };

  buildInputs = with xorg; [ libX11 libXft libXinerama ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "suckless dynamic menu — customised build";
    homepage    = "https://github.com/andre-gonzalez/dmenu";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
