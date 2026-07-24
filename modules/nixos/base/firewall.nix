# Mirrors roles/base/tasks/ufw.yml
# NixOS nftables firewall — equivalent to UFW default-deny + SSH from LAN
{ ... }:
{
  networking.nftables.enable = true;

  networking.firewall = {
    enable = true;

    # No globally open TCP ports; SSH is LAN-restricted via extraInputRules
    allowedTCPPorts = [];
    allowedUDPPorts = [];

    # Allow Tailscale tunnel interface unrestricted
    trustedInterfaces = [ "tailscale0" ];

    # Fine-grained nftables rules
    extraInputRules = ''
      # Allow SSH only from local network. Widened to 192.168.0.0/16 so it
      # works across the various home LANs this laptop roams between
      # (e.g. 192.168.100.0/24), not just 192.168.0.0/24.
      ip saddr 192.168.0.0/16 tcp dport 22 ct state new limit rate 6/minute accept
      ip saddr 192.168.0.0/16 tcp dport 22 accept

      # Drop ICMP echo requests (mirrors ufw/before.rules ping block)
      icmp type echo-request drop
      icmpv6 type echo-request drop
    '';
  };
}
