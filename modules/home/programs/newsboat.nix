# Newsboat RSS reader
{ ... }:
{
  programs.newsboat = {
    enable = true;

    autoReload = true;
    reloadTime  = 60;
    reloadThreads = 4;

    extraConfig = ''
      # Browser
      browser "qutebrowser %u &"

      # Key bindings (vim-like)
      bind-key j down
      bind-key k up
      bind-key J next-feed
      bind-key K prev-feed
      bind-key G end
      bind-key g home
      bind-key d pagedown
      bind-key u pageup
      bind-key l open
      bind-key h quit

      # Colours — Catppuccin Mocha
      color background          default default
      color listnormal          default default
      color listfocus           color15 color237 bold
      color listnormal_unread   color4  default
      color listfocus_unread    color15 color237 bold
      color info                color8  default bold
      color article             default default

      # Podcast / media
      player "mpv"
    '';

    # URLs file — managed by the dotfiles bare repo until migrated here
    # urls = [ ... ];
  };
}
