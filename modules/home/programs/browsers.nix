# Browsers besides qutebrowser — mirrors roles/light_workstation/tasks/web_browser.yml.
#   Helium   — the default browser (helium.desktop handles http/https);
#              pkgs/helium, from the upstream AppImage.
#   Chromium — plain nixpkgs chromium, which already ships the proprietary
#              codecs chromium-ffmpeg added on Arch. NOT chromium-widevine:
#              `chromium.override { enableWideVine = true; }` rebuilds
#              chromium-unwrapped, which is not in the binary cache — a
#              multi-hour compile on every chromium bump. Revisit if DRM video
#              in Chromium is ever needed.
{ pkgs, customPkgs, ... }:
{
  home.packages = [
    customPkgs.helium
    pkgs.chromium
  ];
}
