# Uberall VPN — replaces the AWS VPN Client of roles/work/tasks/aws-vpn.yml,
# which is not in nixpkgs (a .NET app with a root helper service). The
# profile authenticates with auth-user-pass, no SAML (auth-federate) and no
# client certificate, so stock OpenVPN speaks it as is.
#
# `uberall-vpn` runs OpenVPN in the foreground of the terminal it is started
# from: it prompts for the username/password there, and Ctrl-C disconnects.
# The DNS servers the endpoint pushes go to systemd-resolved (the AWS client
# did that itself). dwm_vpn shows the block while tun0 exists.
#
# The profile (endpoint, CA chain) is the agenix secret "uberall-vpn",
# imported from ~/.config/AWSVPNClient/OpenVpnConfigs/uberall-vpn. If the
# endpoint ever moves to SAML/MFA, this stops working and the AWS client is
# the only option.
{ lib, pkgs, ... }:
let
  profile = ../../../secrets/uberall-vpn.age;
  resolved = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
  uberall-vpn = pkgs.writeShellScriptBin "uberall-vpn" ''
    exec /run/wrappers/bin/sudo ${pkgs.openvpn}/bin/openvpn \
      --config /run/agenix/uberall-vpn \
      --script-security 2 \
      --up ${resolved} --up-restart \
      --down ${resolved} --down-pre \
      "$@"
  '';
in
{
  environment.systemPackages = [ pkgs.openvpn uberall-vpn ];

  age.secrets = lib.optionalAttrs (builtins.pathExists profile) {
    uberall-vpn = {
      file = profile;
      owner = "root";
      mode = "0400";
    };
  };
}
