# dwm — main branch from andre-gonzalez's dwm repo.
# One build serves every screen: the ultra-wide handling is runtime logic keyed
# off the monitor width (see patch/ultrawide.c upstream), so there are no longer
# per-machine branches or binaries. config.h patches live in the git branch; no
# patching needed here.
{ stdenv, lib, xorg, fontconfig }:
stdenv.mkDerivation {
  pname = "dwm";
  version = "6.8";

  src = builtins.fetchGit {
    url = "https://github.com/andre-gonzalez/dwm.git";
    ref = "main";
    # Pinned for reproducible pure eval. Update by bumping this rev.
    rev = "b716c8717f195acd6d0c6524824313ba5040f745";
  };

  # libXrender and fontconfig are pulled in by config.mk's LDFLAGS (XRENDER is
  # uncommented upstream for the alpha/winicon patches).
  buildInputs = with xorg; [
    libX11 libXft libXinerama libXrender
    fontconfig
  ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "suckless dynamic window manager — customised build";
    homepage    = "https://github.com/andre-gonzalez/dwm";
    license     = lib.licenses.mit;
    mainProgram = "dwm";
    platforms   = lib.platforms.linux;
  };
}
