# Cursor editor — roles/work/tasks/cursor.yml (AUR cursor-bin on Arch).
# The separately installed Cursor agent CLI (~/.local/bin/cursor shim,
# ~/.local/share/cursor-agent) is self-managed and not part of this.
{ pkgs, ... }:
{
  home.packages = [ pkgs.code-cursor ];
}
