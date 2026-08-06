# Mirrors roles/base/tasks/users.yml
{ pkgs, ... }:
{
  users.users.frank = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adm" "audio" "video" "docker" "libvirtd" "audit" ];
    shell = pkgs.fish;
    hashedPassword = "$6$/5hXHW65FVy.OnGq$lSFIFDiR0yW4/mLT.nIOeT9VGP5HVXIcTwZKQ1xrvQslS35/3FJ95qWPCvDvKLWv0utRqxplpwGuS5G10U4kc1";
    openssh.authorizedKeys.keys = [
      # personal_id_ed25519_2023-11 — used for login after install
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsYIPZvhFhETD4PfqryP/yVpVpRW0bYsrwvPxj5uz/R personal_id_ed25519_2023-11"
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
