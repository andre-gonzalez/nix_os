# slock — simple screen locker from andre-gonzalez's private repo
{ stdenv, lib, libx11, libxext, libxrandr, pam, libxcrypt }:
stdenv.mkDerivation {
  pname = "slock";
  version = "unstable";

  src = builtins.fetchGit {
    url = "https://github.com/andre-gonzalez/slock.git";
    ref = "main";
    rev = "b26f83911e6a601d4cba11d48e5051c5cec3d696";
  };

  buildInputs = [ libx11 libxext libxrandr pam libxcrypt ];

  makeFlags = [ "PREFIX=$(out)" ];
  preBuild = "make clean"; # upstream commits a prebuilt generic-Linux binary; force a real recompile

  # Two distro-specific fixups. These live here rather than in the fork because
  # the fork is shared with Arch.
  #
  #  1. The Makefile's install target runs `chmod u+s`, which fails in the Nix
  #     sandbox. Strip it — setuid is granted at runtime via
  #     security.wrappers.slock (see modules/nixos/desktop/xorg.nix).
  #  2. The committed config.h has `group = "nobody"` (its comment says "use
  #     nobody for arch"). NixOS ships **nogroup**, not nobody, so getgrnam()
  #     fails and slock dies at startup. Only the *group* line is rewritten —
  #     `user = "nobody"` is correct on NixOS and must stay.
  postPatch = ''
    substituteInPlace Makefile --replace-quiet "chmod u+s" "true"
    substituteInPlace config.h --replace-fail 'group = "nobody"' 'group = "nogroup"'
  '';

  meta = {
    description = "suckless screen locker — customised build";
    homepage    = "https://github.com/andre-gonzalez/slock";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
