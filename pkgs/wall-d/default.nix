# wall-d — interactive wallpaper manager (github.com/andre-gonzalez/wall-d),
# mirrors roles/light_workstation/tasks/wall-d.yml. Upstream "installs" by
# copying the script to ~/.local/bin; here it is a store binary instead.
#
# Its tools are appended (--suffix) to PATH rather than prepended, so the
# personal dmenu fork on the user's PATH still wins over nixpkgs' dmenu. rofi
# and pywal (`wal`) are optional modes and are not pulled in.
{ stdenvNoCC, lib, fetchFromGitHub, makeWrapper
, coreutils, gnugrep, gnused, gawk, xrandr, xwallpaper, feh, sxiv, dmenu
}:
stdenvNoCC.mkDerivation {
  pname = "wall-d";
  version = "unstable-2023-10-21";

  src = fetchFromGitHub {
    owner = "andre-gonzalez";
    repo = "wall-d";
    rev = "4ab6141a17505d1b7fda57abba0b9fdf0939d99c"; # master
    hash = "sha256-qelnwct0teJz9AnrwkBbPcUrPdpiCNPrD+gkdW+5CKo=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 wall-d $out/bin/wall-d
    patchShebangs $out/bin/wall-d
    wrapProgram $out/bin/wall-d --suffix PATH : ${lib.makeBinPath [
      coreutils gnugrep gnused gawk xrandr xwallpaper feh sxiv dmenu
    ]}
    runHook postInstall
  '';

  meta = {
    description = "Simple and fast wallpaper manager";
    homepage = "https://github.com/andre-gonzalez/wall-d";
    platforms = lib.platforms.linux;
    mainProgram = "wall-d";
  };
}
