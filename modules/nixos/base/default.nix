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
  ];
}
