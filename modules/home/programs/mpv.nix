# mpv media player
{ pkgs, ... }:
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

    scripts = with pkgs.mpvScripts; [
      sponsorblock
      youtube-upnext
    ];
  };

  home.packages = [ pkgs.yt-dlp ];
}
