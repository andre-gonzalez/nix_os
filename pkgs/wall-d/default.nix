# wall-d — wallpaper daemon / changer
{ stdenv, lib }:
stdenv.mkDerivation {
  pname = "wall-d";
  version = "unstable";

  src = builtins.fetchGit {
    url = "git@github.com:andre-gonzalez/wall-d.git";
    ref = "main";
    # rev = "abc123...";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp wall-d $out/bin/ 2>/dev/null || cp *.sh $out/bin/wall-d || true
    chmod +x $out/bin/wall-d
  '';

  meta = {
    description = "wallpaper daemon";
    homepage    = "https://github.com/andre-gonzalez/wall-d";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
