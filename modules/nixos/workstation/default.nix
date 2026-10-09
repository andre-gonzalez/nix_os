# Everything a laptop gets on top of ../base: frank's personal secrets
# (needs Home Manager), desktop/dev/work packages and ClamAV. Servers import
# ../base alone.
{ ... }:
{
  imports = [
    ./user-secrets.nix
    ./packages.nix
    ./clamav.nix
  ];
}
