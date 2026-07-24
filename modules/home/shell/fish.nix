# Fish user config (~/.config/fish/config.fish, aliases, functions, zoxide/fzf
# init) is managed by the bare dotfiles repo — NOT home-manager. Fish itself is
# enabled system-wide in modules/nixos/base/fish.nix, so we intentionally do
# NOT set programs.fish here: enabling it would generate config.fish and clobber
# the dotfiles copy.
{ ... }:
{
  # intentionally empty — fish configuration lives in the bare dotfiles repo
}
