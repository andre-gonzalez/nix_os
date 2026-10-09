# Mirrors roles/base/tasks/users.yml
{ pkgs, ... }:
{
  users.users.frank = {
    isNormalUser = true;
    # Own primary group, as on Arch (roles/base/tasks/Users.yml), with the same
    # gid so files restored from an Arch backup keep a meaningful group.
    group = "frank";
    extraGroups = [ "wheel" "adm" "audio" "video" "docker" "libvirtd" ];
    shell = pkgs.fish;
    hashedPassword = "$6$/5hXHW65FVy.OnGq$lSFIFDiR0yW4/mLT.nIOeT9VGP5HVXIcTwZKQ1xrvQslS35/3FJ95qWPCvDvKLWv0utRqxplpwGuS5G10U4kc1";
    openssh.authorizedKeys.keys = [
      # personal_id_ed25519_2023-11 — used for login after install
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsYIPZvhFhETD4PfqryP/yVpVpRW0bYsrwvPxj5uz/R personal_id_ed25519_2023-11"
    ];
  };

  users.groups.frank.gid = 1000;

  # ansible service account (no login, wheel access for automation)
  users.users.ansible = {
    isSystemUser = true;
    group = "ansible";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
  };
  users.groups.ansible = {};

  security.sudo.extraRules = [
    # Deliberately PASSWD, unlike Arch's sudoers.d/frank (NOPASSWD: ALL): sudo
    # asks for the fingerprint (t14) or the password, so code running as frank
    # cannot become root unasked. Only the commands below skip the prompt.
    {
      users = [ "frank" ];
      commands = [{ command = "ALL"; options = [ "PASSWD" ]; }];
    }
    {
      users = [ "ansible" ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
    }
    # frank can unmount the external drives and run rsync as root without a
    # password (roles/base/files/sudoers_frank). umount is a setuid wrapper on
    # NixOS, so both its paths are listed; /usr/bin does not exist here.
    {
      users = [ "frank" ];
      commands = map (command: { inherit command; options = [ "NOPASSWD" ]; }) [
        "/run/wrappers/bin/umount /mnt/hd-externo"
        "/run/wrappers/bin/umount /mnt/ntfs-hd-externo"
        "/run/current-system/sw/bin/umount /mnt/hd-externo"
        "/run/current-system/sw/bin/umount /mnt/ntfs-hd-externo"
        "/run/current-system/sw/bin/rsync"
        "/etc/profiles/per-user/frank/bin/rsync"
      ];
    }
  ];
}
