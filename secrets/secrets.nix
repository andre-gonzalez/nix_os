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
  # t14 host key (ThinkPad T14 Gen 6, replaces the old `workstation` host).
  # The private half is generated pre-wipe and injected at install time to
  # /etc/ssh/ssh_host_ed25519_key from .extra-files/t14/etc/ssh/… — keep an
  # off-machine copy, agenix cannot decrypt anything on t14 without it.
  t14         = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9UHH3o7Pjbyc2XI6O3uiuxQ4cqht2WfJl7ZfWOVcNa root@t14";
  # samsung-expert host key — the private half is injected at install time via
  # nixos-anywhere --extra-files (.extra-files/samsung-expert/etc/ssh/…).
  samsung     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOf8USifZFCLDMg2AisIwnNlQvS0ykipHGk6AbH8M7z root@samsung-expert";
  # frank's personal key = ~/.ssh/personal_id_ed25519_2023-11 (used to edit secrets).
  frank       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsYIPZvhFhETD4PfqryP/yVpVpRW0bYsrwvPxj5uz/R personal_id_ed25519_2023-11";

  allHosts = [ t14 samsung frank ];
in
{
  "ssh-port.age".publicKeys           = allHosts;
  "tailscale-authkey.age".publicKeys  = allHosts;

  # iwd network profile, deployed to /var/lib/iwd/QUEWIFI-5G.psk so the machine
  # auto-connects headless on first boot. Other networks are added at runtime
  # with `iwctl` (iwd persists them in /var/lib/iwd).
  "iwd-QUEWIFI-5G.age".publicKeys     = [ t14 samsung frank ];

  "aws-credentials.age".publicKeys    = [ t14 frank ];

  "neomutt-personal.age".publicKeys   = allHosts;
  "neomutt-uberall.age".publicKeys    = allHosts;
  "neomutt-athenaworks.age".publicKeys = allHosts;

  "msmtp.age".publicKeys              = allHosts;
  "mbsyncrc.age".publicKeys           = allHosts;

  "rclone.age".publicKeys             = allHosts;
}
