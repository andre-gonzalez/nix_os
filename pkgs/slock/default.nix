# slock — simple screen locker from andre-gonzalez's private repo
{ stdenv, lib, xorg, pam }:
stdenv.mkDerivation {
  pname = "slock";
  version = "unstable";

  src = builtins.fetchGit {
    url = "https://github.com/andre-gonzalez/slock.git";
    ref = "main";
    rev = "b26f83911e6a601d4cba11d48e5051c5cec3d696";
  };

  buildInputs = with xorg; [ libX11 libXext libXrandr pam ];

  makeFlags = [ "PREFIX=$(out)" ];

  # The Makefile's install target runs `chmod u+s`, which fails in the Nix
  # sandbox. Strip it here — setuid is granted at runtime via
  # security.wrappers.slock (see modules/nixos/desktop/xorg.nix).
  postPatch = ''
    substituteInPlace Makefile --replace-quiet "chmod u+s" "true"
  '';

  meta = {
    description = "suckless screen locker — customised build";
    homepage    = "https://github.com/andre-gonzalez/slock";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
