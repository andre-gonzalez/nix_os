{ ... }:
{
  imports = [
    ./users.nix
    ./user-secrets.nix
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
