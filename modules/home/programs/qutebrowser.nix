# Qutebrowser with Python ad-block (python-adblock on Arch)
{ pkgs, ... }:
{
  programs.qutebrowser = {
    enable = true;

    extraConfig = ''
      # Enable adblock
      c.content.blocking.enabled = True
      c.content.blocking.method = 'both'
      c.content.blocking.adblock.lists = [
          'https://easylist.to/easylist/easylist.txt',
          'https://easylist.to/easylist/easyprivacy.txt',
          'https://secure.fanboy.co.nz/fanboy-cookiemonster.txt',
      ]

      # PDF handling via zathura
      c.content.pdfjs = False

      # Fonts
      c.fonts.default_family = 'JetBrainsMono Nerd Font'
      c.fonts.default_size = '11pt'

      # Catppuccin Mocha color scheme
      c.colors.webpage.preferred_color_scheme = 'dark'
      c.colors.webpage.darkmode.enabled = True
    '';

    settings = {
      editor.command = [ "st" "-e" "nvim" "{}" ];
      downloads.location.directory = "~/Downloads";
      content.javascript.enabled = true;
    };
  };

  # python-adblock must be importable by qutebrowser
  home.packages = [ pkgs.python3Packages.adblock ];
}
