# st — simple terminal from andre-gonzalez's private repo
{ stdenv, lib, xorg, harfbuzz, fontconfig, freetype, ncurses }:
stdenv.mkDerivation {
  pname = "st";
  version = "unstable";

  src = builtins.fetchGit {
    url = "https://github.com/andre-gonzalez/st.git";
    ref = "main";
    rev = "5f84391724811c1bf6b5d5c58b01659c44f54882";
  };

  # ncurses provides `tic`, used by the Makefile's install target to compile
  # the st terminfo entry.
  nativeBuildInputs = [ ncurses ];

  buildInputs = with xorg; [
    libX11 libXft
    harfbuzz fontconfig freetype
  ];

  makeFlags = [ "PREFIX=$(out)" ];
  preBuild = "make clean"; # upstream commits a prebuilt generic-Linux binary; force a real recompile
  NIX_LDFLAGS = "-lfontconfig"; # st calls fontconfig directly; modern ld needs it explicit

  # The Makefile's install runs `tic` to compile the terminfo entry; by default
  # it writes to $HOME/.terminfo, which doesn't exist in the sandbox. Direct it
  # into $out instead.
  preInstall = ''
    export TERMINFO=$out/share/terminfo
    mkdir -p $TERMINFO
  '';

  meta = {
    description = "suckless simple terminal — customised build";
    homepage    = "https://github.com/andre-gonzalez/st";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
