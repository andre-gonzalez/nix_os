# mpv media player
{ config, lib, pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    config = {
      # Video
      hwdec = "auto-safe";
      vo     = "gpu";
      gpu-api = "opengl";

      # Audio
      audio-display  = false;
      audio-file-auto = "fuzzy";

      # Interface
      osc      = false;   # use uosc / custom OSD if desired
      osd-level = 1;
      osd-font-size = 30;

      # Subtitles
      sub-auto = "fuzzy";
      sub-font-size = 40;
      sub-bold = true;

      # Behaviour
      loop-playlist = "inf";
      ytdl-format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";
    };

    # Metered-network overrides written by ~/.scripts/save-data (empty when
    # off). home-manager appends includes at the end of mpv.conf, so they
    # override config above; a [profile] section added later would swallow it.
    includes = [ "~~/save-data.conf" ];

    scripts = with pkgs.mpvScripts; [
      sponsorblock
      youtube-upnext
    ];
  };

  home.packages = [ pkgs.yt-dlp ];

  # save-data owns this file, so it is not a store link; create it empty so
  # mpv does not report a missing include before the script first runs.
  home.activation.mpvSaveData = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    conf="${config.xdg.configHome}/mpv/save-data.conf"
    if [ ! -e "$conf" ]; then
      $DRY_RUN_CMD mkdir -p "''${conf%/*}"
      $DRY_RUN_CMD touch "$conf"
    fi
  '';
}
