# st — simple terminal from andre-gonzalez's private repo
{ stdenv, lib, xorg, harfbuzz, fontconfig, freetype }:
stdenv.mkDerivation {
  pname = "st";
  version = "unstable";

  src = builtins.fetchGit {
    url = "git@github.com:andre-gonzalez/st.git";
    ref = "main";
    # rev = "abc123...";
  };

  buildInputs = with xorg; [
    libX11 libXft
    harfbuzz fontconfig freetype
  ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "suckless simple terminal — customised build";
    homepage    = "https://github.com/andre-gonzalez/st";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
