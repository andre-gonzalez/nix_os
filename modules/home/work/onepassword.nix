# 1Password desktop + CLI
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    _1password-gui
    _1password-cli
  ];

  # 1Password system integration requires the setuid wrapper; enable at system level:
  # programs._1password.enable = true;
  # programs._1password-gui.enable = true;
  # programs._1password-gui.polkitPolicyOwners = [ "frank" ];
}
