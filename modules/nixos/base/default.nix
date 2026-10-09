# What every host gets, servers included. Laptop-only parts (personal secrets,
# desktop and dev packages, ClamAV) are in ../workstation.
{ ... }:
{
  imports = [
    ./users.nix
    ./locale.nix
    ./packages.nix
    ./ssh.nix
    ./security.nix
    ./network.nix
    ./firewall.nix
    ./fish.nix
    ./fstrim.nix
  ];
}
