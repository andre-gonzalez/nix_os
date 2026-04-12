# Neovim — set as git editor; plugin management via nixpkgs or lazy.nvim
{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # System-level language support packages
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil             # Nix LSP
      nodePackages.typescript-language-server
      pyright
      terraform-ls

      # Tools used by plugins
      ripgrep
      fd
      tree-sitter

      # Debugger adapter
      python3Packages.debugpy
    ];

    # Let the dotfiles repo / lazy.nvim manage the full plugin tree (Option A).
    # Plugins can be migrated here incrementally.
    extraLuaConfig = ''
      -- Bootstrap lazy.nvim if not present
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
          "git", "clone", "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable", lazypath,
        })
      end
      vim.opt.rtp:prepend(lazypath)

      -- Remaining config lives in ~/.config/nvim/ (managed by dotfiles repo)
    '';
  };
}
