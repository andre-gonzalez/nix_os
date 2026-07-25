# Neovim. Config (~/.config/nvim/, lazy.nvim plugin tree) is managed by the bare
# dotfiles repo, so home-manager only installs neovim plus the LSP servers and
# tools its plugins expect (no programs.neovim, which would generate init.lua).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim

    # LSP servers
    lua-language-server
    nil                # Nix LSP
    typescript-language-server
    pyright
    terraform-ls

    # Tools used by plugins
    ripgrep
    fd
    tree-sitter

    # Debugger adapter
    python3Packages.debugpy
  ];
}
