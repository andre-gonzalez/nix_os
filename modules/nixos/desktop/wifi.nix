# WiFi via iwd + the known networks — mirrors roles/light_workstation/tasks/wifi.yml
#
# iwd rather than NetworkManager: all known networks are PSK or open, no 802.1X
# anywhere. iwd runs its own DHCP and hands DNS to systemd-resolved; `iwctl`
# adds further networks at runtime (iwd persists them in /var/lib/iwd).
#
# Each profile is an agenix secret decrypted straight to /var/lib/iwd/<SSID>.psk
# — a real file (symlink = false) with 0600 perms, as iwd requires. A profile
# is only wired once its .age file exists *and is tracked by git* (a flake
# cannot see untracked files), so the config evaluates before every secret has
# been migrated from the Ansible vault.
{ lib, ... }:
let
  # agenix secret name -> iwd profile file name. iwd hex-encodes SSIDs with
  # characters outside [A-Za-z0-9_-] and prefixes them with '=':
  # "=51756520576966693f" is the SSID "QueWifi?".
  networks = {
    "iwd-QUEWIFI-5G" = "QUEWIFI-5G.psk"; # home network: auto-connect on first boot
    "iwd-Lopes" = "Lopes.psk";
    "iwd-LNAM5" = "LNAM5.psk";
    "iwd-QueWiFi2" = "QueWiFi2.psk";
    "iwd-CasaRio_5G" = "CasaRio_5G.psk";
    "iwd-QueWifi-question" = "=51756520576966693f.psk";
    "iwd-Davi" = "Davi.psk";
  };

  file = name: ../../../secrets/${name}.age;
  present = lib.filterAttrs (name: _: builtins.pathExists (file name)) networks;
in
{
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = true; # iwd runs DHCP
      Network.NameResolvingService = "systemd";  # integrate with systemd-resolved
    };
  };

  # agenix places the profiles during activation, before iwd.service gets a
  # chance to create its StateDirectory.
  systemd.tmpfiles.rules = [ "d /var/lib/iwd 0700 root root -" ];

  age.secrets = lib.mapAttrs (name: profile: {
    file = file name;
    path = "/var/lib/iwd/${profile}";
    mode = "0600";
    owner = "root";
    group = "root";
    symlink = false; # iwd needs a real file with strict perms, not a symlink
  }) present;
}
