# Helium — the default browser (helium.desktop handles http/https), a
# Chromium-based browser from imputnet. Not in nixpkgs; Arch used the AUR's
# helium-browser-bin. Built from the official x86_64 AppImage.
#
# Both command names exist, as on Arch: `helium` (upstream) and
# `helium-browser` (what the AUR package installs, and what the shell history
# and any --app= launchers call). The desktop file keeps the name
# helium.desktop, which is what xdg-mime's default-browser entry points at.
{ lib, appimageTools, fetchurl }:
let
  pname = "helium";
  version = "0.19.2.1";
  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-oEVQo8fHC9rTrNOkQw7ajSr8C/cXOpxYpAP+q5UXCH8=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    ln -s $out/bin/helium $out/bin/helium-browser

    desktop=$(find ${contents} -maxdepth 1 -name '*.desktop' | head -n1)
    install -Dm644 "$desktop" $out/share/applications/helium.desktop
    substituteInPlace $out/share/applications/helium.desktop \
      --replace-quiet 'Exec=AppRun' 'Exec=helium'
    cp -r ${contents}/usr/share/icons $out/share/ 2>/dev/null || true
  '';

  meta = {
    description = "Private, fast and honest Chromium-based web browser";
    homepage = "https://helium.computer";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
