# System-wide fish shell configuration
{ pkgs, ... }:
{
  programs.fish.enable = true;

  # Set fish as the default shell system-wide
  users.defaultUserShell = pkgs.fish;

  # Ensure fish is in /etc/shells
  environment.shells = [ pkgs.fish ];
}
