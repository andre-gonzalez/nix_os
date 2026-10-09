# Tailscale VPN — mirrors roles/base (artis3n.tailscale role)
{ config, lib, ... }:
let
  authKey = ../../../secrets/tailscale-authkey.age;
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Ansible ran `tailscale up --authkey …` once per machine. The NixOS
    # equivalent is tailscaled-autoconnect.service, which only runs `tailscale
    # up` while the node is logged out — so an expired key in the secret is
    # harmless once the machine has joined. Keyed on age.secrets rather than
    # the file so that t14-remote, which clears age.secrets, falls back to an
    # interactive `sudo tailscale up`.
    authKeyFile = lib.mkIf (config.age.secrets ? tailscale-authkey)
      config.age.secrets.tailscale-authkey.path;
  };

  # Wired only once the .age file exists and is tracked by git (see
  # secrets/import-from-ansible.sh).
  age.secrets = lib.optionalAttrs (builtins.pathExists authKey) {
    tailscale-authkey = {
      file = authKey;
      owner = "root";
      mode = "0400";
    };
  };

  # Allow Tailscale interface in firewall (also set in firewall.nix trustedInterfaces)
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
