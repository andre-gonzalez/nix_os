# Tailscale VPN — mirrors roles/base (artis3n.tailscale role)
{ config, ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Auth key provided via agenix secret at activation time:
    # authKeyFile = config.age.secrets.tailscale-authkey.path;
  };

  # Allow Tailscale interface in firewall (also set in firewall.nix trustedInterfaces)
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Wire agenix secret when populated:
  # age.secrets.tailscale-authkey = {
  #   file = ../../secrets/tailscale-authkey.age;
  #   owner = "root";
  # };
}
