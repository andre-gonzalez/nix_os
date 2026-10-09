# frank's personal secrets — mirrors the vaulted files the Ansible
# light_workstation role copied into $HOME:
#   tasks/ssh.yml           ~/.ssh/personal_id_ed25519_2023-11{,.pub}, ~/.ssh/config
#   tasks/rclone.yml        ~/.config/rclone/rclone.conf
#   tasks/linux-scripts.yml ~/.scripts/.env/{instapaper,ipinfo,people,mac-address-proxmox-server}
#   roles/work             ~/.aws/config, ~/.databrickscfg, ~/.databricks-connect
#                          (seeded by home/work/{aws,databricks}.nix)
#
# agenix is a NixOS module, so the secrets are decrypted to /run/agenix/<name>
# (owned by frank, 0400) and Home Manager puts them in place. Each one is only
# wired once its .age file exists *and is tracked by git* (a flake cannot see
# untracked files) — see secrets/import-from-ansible.sh.
{ lib, ... }:
let
  file = name: ../../../secrets/${name}.age;
  has = name: builtins.pathExists (file name);

  names = [
    "ssh-personal-key"
    "ssh-config"
    "rclone"
    "scripts-env-instapaper"
    "scripts-env-ipinfo"
    "scripts-env-people"
    "scripts-env-mac-address-proxmox-server"
    "aws-config"
    "databrickscfg"
    "databricks-connect"
  ];

  scriptsEnv = lib.filter has [
    "scripts-env-instapaper"
    "scripts-env-ipinfo"
    "scripts-env-people"
    "scripts-env-mac-address-proxmox-server"
  ];
in
{
  age.secrets = lib.listToAttrs (map (name: {
    inherit name;
    value = {
      file = file name;
      owner = "frank";
      group = "frank";
      mode = "0400";
    };
  }) (lib.filter has names));

  # hosts/t14/INSTALL.md restores ~/.ssh from a backup, so ~/.ssh/config and
  # the key may already exist as real files on first activation. Without a
  # backup extension Home Manager refuses to replace them and the whole
  # home-manager-frank.service fails; with it they are renamed to *.pre-hm.
  home-manager.backupFileExtension = "pre-hm";

  home-manager.users.frank = { config, lib, pkgs, ... }:
    let
      link = name: config.lib.file.mkOutOfStoreSymlink "/run/agenix/${name}";
    in
    {
      # Read-only consumers: a symlink to /run/agenix is enough. ssh checks the
      # owner and mode of the target, which agenix sets to frank / 0400.
      home.file = lib.mkMerge [
        {
          ".ssh/personal_id_ed25519_2023-11.pub".text =
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsYIPZvhFhETD4PfqryP/yVpVpRW0bYsrwvPxj5uz/R personal_id_ed25519_2023-11\n";
        }
        (lib.mkIf (has "ssh-personal-key") {
          ".ssh/personal_id_ed25519_2023-11".source = link "ssh-personal-key";
        })
        (lib.mkIf (has "ssh-config") {
          ".ssh/config".source = link "ssh-config";
        })
      ];

      # rclone rewrites its config whenever an OAuth token is refreshed, so it
      # needs a writable copy, not a symlink. Seed it once; never overwrite.
      home.activation.seedRcloneConf = lib.mkIf (has "rclone")
        (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ ! -e "$HOME/.config/rclone/rclone.conf" ] && [ -r /run/agenix/rclone ]; then
            $DRY_RUN_CMD install -D -m 0600 /run/agenix/rclone "$HOME/.config/rclone/rclone.conf"
          fi
        '');

      # ~/.scripts is a git clone made by home/scripts.nix during activation, so
      # these cannot be home.file entries (HM would create ~/.scripts first and
      # the clone would be skipped). Copied on every activation, like Ansible did.
      home.activation.scriptsEnv = lib.mkIf (scriptsEnv != [ ])
        (lib.hm.dag.entryAfter [ "cloneScripts" ] (lib.concatMapStrings (name: ''
          if [ -d "$HOME/.scripts" ] && [ -r /run/agenix/${name} ]; then
            $DRY_RUN_CMD install -D -m 0600 /run/agenix/${name} \
              "$HOME/.scripts/.env/${lib.removePrefix "scripts-env-" name}"
          fi
        '') scriptsEnv));
    };
}
