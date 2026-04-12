# slock — simple screen locker from andre-gonzalez's private repo
{ stdenv, lib, xorg, pam }:
stdenv.mkDerivation {
  pname = "slock";
  version = "unstable";

  src = builtins.fetchGit {
    url = "git@github.com:andre-gonzalez/slock.git";
    ref = "main";
    # rev = "abc123...";
  };

  buildInputs = with xorg; [ libX11 libXext libXrandr pam ];

  makeFlags = [ "PREFIX=$(out)" ];

  # slock requires setuid root for PAM auth
  postInstall = ''
    chmod u+s $out/bin/slock
  '';

  meta = {
    description = "suckless screen locker — customised build";
    homepage    = "https://github.com/andre-gonzalez/slock";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
