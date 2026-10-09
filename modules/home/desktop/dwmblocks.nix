# dwmblocks-async (pkgs/dwmblocks) — started from .xinitrc in the dotfiles.
#
# The repo also ships two watchers that refresh a block on an event instead of
# on its timer. Upstream's units are WantedBy=graphical-session.target, which a
# startx + dwm session never reaches — on Arch they were enabled but never ran.
# Here they start with the user manager instead; both only need the system or
# session D-Bus, not X, and `pkill dwmblocks` is a no-op until the bar is up.
{ customPkgs, ... }:
let
  pkg = customPkgs.dwmblocks;
  watcher = description: exec: {
    Unit = {
      Description = description;
      After = [ "dbus.socket" ];
    };
    Service = {
      ExecStart = exec;
      Restart = "always";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };
in
{
  home.packages = [ pkg ];

  systemd.user.services = {
    # Bluetooth block (signal 12) on device connect/disconnect.
    dwmblocks-bluetooth = watcher
      "Refresh the dwmblocks bluetooth block on device connect/disconnect"
      "${pkg}/bin/dwmblocks-bluetooth";

    # Phone battery block, from KDE Connect's D-Bus signals.
    dwmblocks-kdeconnect = watcher
      "Refresh the dwmblocks phone battery block on KDE Connect changes"
      "${pkg}/bin/dwm_kdeconnect --watch";
  };
}
