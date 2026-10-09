# Pi-hole (stacks/dns) publishes port 53 on every address of this host, which
# systemd-resolved's stub listener on 127.0.0.53:53 conflicts with —
# docker-proxy cannot bind 0.0.0.0:53 while it holds the port.
#
# The host itself keeps resolving through resolved, straight to the upstreams
# in base/network.nix (1.1.1.3), never through its own Pi-hole: pulling an
# image or fetching the repo must still work while the dns stack is down.
{ lib, ... }:
{
  services.resolved.settings.Resolve.DNSStubListener = "no";

  # resolved's default /etc/resolv.conf points at the stub (127.0.0.53), which
  # no longer answers. This one lists the real upstreams; docker also hands
  # them to containers on the default bridge.
  environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/resolv.conf";
}
