# notas — personal note-taking tool
{ stdenv, lib }:
stdenv.mkDerivation {
  pname = "notas";
  version = "unstable";

  src = builtins.fetchGit {
    url = "git@github.com:andre-gonzalez/notas.git";
    ref = "main";
    # rev = "abc123...";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp notas $out/bin/ 2>/dev/null || cp *.sh $out/bin/notas || true
    chmod +x $out/bin/notas
  '';

  meta = {
    description = "personal note-taking CLI tool";
    homepage    = "https://github.com/andre-gonzalez/notas";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
