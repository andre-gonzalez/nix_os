# agenix secrets manifest
# Each .age file in this directory is encrypted for the listed public keys.
#
# To populate host public keys:
#   nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
#
# To populate your personal age key:
#   nix run nixpkgs#age -- -keygen -o ~/.config/sops/age/keys.txt
#
# To re-encrypt the ansible-vault secrets: secrets/import-from-ansible.sh

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

  # iwd network profiles, decrypted to /var/lib/iwd/<SSID>.psk by
  # modules/nixos/desktop/wifi.nix. QUEWIFI-5G lets a fresh install auto-connect
  # headless on first boot; the rest are the networks the Ansible role shipped.
  # Others are added at runtime with `iwctl` (iwd persists them).
  "iwd-QUEWIFI-5G.age".publicKeys       = allHosts;
  "iwd-Lopes.age".publicKeys            = allHosts;
  "iwd-LNAM5.age".publicKeys            = allHosts;
  "iwd-QueWiFi2.age".publicKeys         = allHosts;
  "iwd-CasaRio_5G.age".publicKeys       = allHosts;
  "iwd-QueWifi-question.age".publicKeys = allHosts; # SSID "QueWifi?"
  "iwd-Davi.age".publicKeys             = allHosts;

  # frank's personal files (modules/nixos/workstation/user-secrets.nix).
  "ssh-personal-key.age".publicKeys     = allHosts; # ~/.ssh/personal_id_ed25519_2023-11
  "ssh-config.age".publicKeys           = allHosts; # ~/.ssh/config
  "scripts-env-instapaper.age".publicKeys                 = allHosts;
  "scripts-env-ipinfo.age".publicKeys                     = allHosts;
  "scripts-env-people.age".publicKeys                     = allHosts;
  "scripts-env-mac-address-proxmox-server.age".publicKeys = allHosts;
  "gpg-secret-keys.age".publicKeys      = allHosts; # secrets/export-gpg-keys.sh

  # Work (home/work/*.nix), imported from the live Arch files — the vaulted
  # Ansible copies are older (AWS keys before SSO, a past employer's Databricks).
  "aws-config.age".publicKeys          = allHosts; # ~/.aws/config (SSO profiles)
  "databrickscfg.age".publicKeys       = allHosts; # ~/.databrickscfg
  "databricks-connect.age".publicKeys  = allHosts; # ~/.databricks-connect
  "uberall-vpn.age".publicKeys         = allHosts; # OpenVPN profile (nixos/desktop/uberall-vpn.nix)

  "rclone.age".publicKeys             = allHosts;
}
