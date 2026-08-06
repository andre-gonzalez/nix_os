# Bluetooth daemon
{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  # Bridge Bluetooth AVRCP (headset play/pause/next buttons) to MPRIS players.
  systemd.user.services.mpris-proxy = {
    description = "Forward bluetooth media controls to MPRIS";
    after = [ "network.target" "sound.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };

  environment.systemPackages = [ pkgs.bluez ];
}
