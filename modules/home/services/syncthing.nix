# Syncthing — currently disabled (easy to toggle)
{ ... }:
{
  services.syncthing = {
    enable = false; # set true to enable
    # tray.enable = true; # requires syncthingtray package
  };
}
