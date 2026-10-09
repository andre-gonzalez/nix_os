# 1Password — roles/work/tasks/one-password.yml. Through the NixOS modules,
# not home.packages: the GUI needs its setgid helper and a polkit policy for
# system authentication and browser-extension integration, which a plain
# package cannot install. The CLI (`op`) is enabled for its integration with
# the GUI's unlock.
{ ... }:
{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "frank" ];
  };
}
