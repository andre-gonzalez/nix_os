# Cursor AI editor (AUR: cursor-bin on Arch)
# Not yet in nixpkgs — use the AppImage wrapper below.
{ pkgs, ... }:
{
  home.packages = [
    # Uncomment when a proper derivation is available or write one in pkgs/cursor/:
    # (pkgs.appimageTools.wrapAppImage {
    #   name = "cursor";
    #   src = pkgs.fetchurl {
    #     url = "https://downloader.cursor.sh/linux/appImage/x64";
    #     sha256 = lib.fakeSha256; # replace with actual hash
    #   };
    # })
    pkgs.vscode  # temporary fallback until cursor derivation is ready
  ];
}
