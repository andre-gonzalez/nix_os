# Codecs / multimedia backend — mirrors the gstreamer + ffmpeg packages that
# roles/light_workstation installed on Arch (gst-libav, gst-plugins-{good,bad,ugly},
# ffmpeg). gst-plugins-base and the gstreamer core come along because every
# other plugin set is useless without them (on Arch they arrived as deps).
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav

    # Arch's ffmpeg is built with essentially every optional codec enabled;
    # ffmpeg-full is the nixpkgs equivalent (plain `ffmpeg` is a smaller build).
    ffmpeg-full
  ];

  # GStreamer only scans the plugin dir baked into its own store path, so
  # plugins dropped into the system profile are invisible without this. NixOS
  # links package `/lib` into /run/current-system/sw, so pointing at the profile
  # picks up whatever is listed above (and anything added later).
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
    "/run/current-system/sw/lib/gstreamer-1.0";
}
