# KDE Connect — phone integration. Installed by hand on Arch (not in Ansible);
# the dwmblocks phone-battery block and its dwmblocks-kdeconnect watcher
# (home/desktop/dwmblocks.nix) read it over D-Bus. kdeconnectd is D-Bus
# activated, so it needs no service of its own under startx.
#
# The module opens 1714-1764 TCP+UDP, which KDE Connect needs to discover and
# reach the phone.
{ ... }:
{
  programs.kdeconnect.enable = true;
}
