# Mirrors roles/base/tasks/users.yml
{ pkgs, ... }:
{
  users.users.frank = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adm" "audio" "video" "docker" "libvirtd" "audit" ];
    shell = pkgs.fish;
    # SSH keys fetched from GitHub; commit the fetched file or use fetchurl at build time
    openssh.authorizedKeys.keyFiles = [
      # (pkgs.fetchurl {
      #   url = "https://github.com/andre-gonzalez.keys";
      #   sha256 = "...";
      # })
    ];
  };

  # ansible service account (no login, wheel access for automation)
  users.users.ansible = {
    isSystemUser = true;
    group = "ansible";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
  };
  users.groups.ansible = {};

  security.sudo.extraRules = [
    {
      users = [ "frank" ];
      commands = [{ command = "ALL"; options = [ "PASSWD" ]; }];
    }
    {
      users = [ "ansible" ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
    }
    # frank can umount backup drives without password (mirrors sudoers.d/frank)
    {
      users = [ "frank" ];
      commands = [
        { command = "/usr/bin/umount /mnt/backup*"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/umount /mnt/backup*"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
