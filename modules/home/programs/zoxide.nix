# zoxide + fzf — fast directory jumping
{ pkgs, ... }:
{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    historyWidgetOptions = [ "--sort" "--exact" ];
    colors = {
      bg      = "#1e1e2e";
      "bg+"   = "#313244";
      fg      = "#cdd6f4";
      "fg+"   = "#cdd6f4";
      hl      = "#f38ba8";
      "hl+"   = "#f38ba8";
      info    = "#cba6f7";
      marker  = "#f5e0dc";
      prompt  = "#cba6f7";
      spinner = "#f5e0dc";
      pointer = "#f5e0dc";
      header  = "#ed8796";
    };
  };
}
