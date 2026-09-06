# Bluetooth daemon
{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  # Bridge Bluetooth AVRCP (headset play/pause/next buttons) to MPRIS players.
  #
  # Enablement and ordering only, deliberately no ExecStart: bluez already ships
  # mpris-proxy.service (with the right ExecStart and WantedBy=default.target),
  # and because the unit name comes from a package, NixOS renders whatever we
  # set here as a drop-in rather than as a replacement unit. A second ExecStart=
  # in a Type=simple unit is a hard error — systemd refuses to start it at all:
  #   mpris-proxy.service: Service has more than one ExecStart= setting, which
  #   is only allowed for Type=oneshot services. Refusing.
  # (To genuinely replace the command it would have to be
  # `ExecStart = [ "" "..." ]`, where the empty string clears the packaged one.)
  systemd.user.services.mpris-proxy = {
    after = [ "network.target" "sound.target" ];
    wantedBy = [ "default.target" ];
  };

  environment.systemPackages = [ pkgs.bluez ];
}
