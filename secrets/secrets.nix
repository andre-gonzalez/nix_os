# agenix secrets manifest
# Each .age file in this directory is encrypted for the listed public keys.
#
# To populate host public keys:
#   nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
#
# To populate your personal age key:
#   nix run nixpkgs#age -- -keygen -o ~/.config/sops/age/keys.txt
#
# To re-encrypt an ansible-vault secret:
#   ansible-vault decrypt --vault-password-file ~/ansi-vault-pass <file> --output - \
#     | agenix -e secrets/<name>.age

let
  # agenix uses SSH keys directly as recipients (age's native ssh support),
  # so these are plain SSH public keys — NOT ssh-to-age (age1…) conversions.
  # workstation host key is still a placeholder; populate it before encrypting
  # any secret to `workstation`.
  workstation = "ssh-ed25519 AAAA_REPLACE_WITH_WORKSTATION_HOST_KEY root@workstation";
  # samsung-expert host key — the private half is injected at install time via
  # nixos-anywhere --extra-files (.extra-files/samsung-expert/etc/ssh/…).
  samsung     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOf8USifZFCLDMg2AisIwnNlQvS0ykipHGk6AbH8M7z root@samsung-expert";
  # frank's personal key = ~/.ssh/personal_id_ed25519_2023-11 (used to edit secrets).
  frank       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsYIPZvhFhETD4PfqryP/yVpVpRW0bYsrwvPxj5uz/R personal_id_ed25519_2023-11";

  allHosts = [ workstation samsung frank ];
in
{
  "ssh-port.age".publicKeys           = allHosts;
  "tailscale-authkey.age".publicKeys  = allHosts;

  "wifi-lopes.age".publicKeys         = allHosts;
  "wifi-lnam5.age".publicKeys         = allHosts;
  # Only encrypted for samsung + frank (workstation key not yet populated).
  "wifi-queWifi2.age".publicKeys      = [ samsung frank ];
  "wifi-casaRio5g.age".publicKeys     = allHosts;

  "aws-credentials.age".publicKeys    = [ workstation frank ];

  "neomutt-personal.age".publicKeys   = allHosts;
  "neomutt-uberall.age".publicKeys    = allHosts;
  "neomutt-athenaworks.age".publicKeys = allHosts;

  "msmtp.age".publicKeys              = allHosts;
  "mbsyncrc.age".publicKeys           = allHosts;

  "rclone.age".publicKeys             = allHosts;
}
