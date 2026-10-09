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

    # Drop ICMP echo requests (mirrors ufw/before.rules ping block). This has
    # to be allowPing: the module's own "allow ping" rule sits *before*
    # extraInputRules in input-allow, so an `icmp type echo-request drop` there
    # never matched. (ICMPv6 echo is still accepted by the module's blanket
    # icmpv6 rule, which also precedes extraInputRules.)
    allowPing = false;

    # Fine-grained nftables rules
    extraInputRules = ''
      # Allow SSH only from local network. Widened to 192.168.0.0/16 so it
      # works across the various home LANs this laptop roams between
      # (e.g. 192.168.100.0/24), not just 192.168.0.0/24. The port is a secret
      # resolved at boot into the ssh_port set (see ssh.nix).
      ip saddr 192.168.0.0/16 tcp dport @ssh_port ct state new limit rate 6/minute accept
      ip saddr 192.168.0.0/16 tcp dport @ssh_port accept
    '';
  };
}
