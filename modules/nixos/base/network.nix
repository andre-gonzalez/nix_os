# Mirrors roles/base/tasks/network.yml — DNS via systemd-resolved
{ ... }:
{
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    # Cloudflare family DNS (no malware/adult content) — mirrors /etc/resolv.conf
    fallbackDns = [ "1.1.1.3" "1.0.0.3" ];
    # `extraConfig` was removed; use structured settings (maps to the
    # [Resolve] section of resolved.conf).
    settings.Resolve = {
      DNS = "1.1.1.3 1.0.0.3";
      DNSOverTLS = "opportunistic";
    };
  };

  # Disable static resolv.conf so systemd-resolved manages it
  networking.resolvconf.enable = false;
}
