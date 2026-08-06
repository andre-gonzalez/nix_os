# autorandr service — profiles are managed per-user in home/desktop/
# System-level: install the binary and enable the systemd service
{ pkgs, ... }:
{
  services.autorandr.enable = true;

  environment.systemPackages = [ pkgs.autorandr pkgs.arandr ];
}
