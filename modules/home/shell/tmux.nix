# tmux + tmuxp
{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    historyLimit = 50000;
    escapeTime = 0;
    keyMode = "vi";

    extraConfig = ''
      # Mouse support
      set -g mouse on

      # True color
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Prefix → Ctrl-a (screen-like)
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      # Split panes
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # Status bar
      set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
      set -g status-left "#[fg=#89b4fa,bold] [#S] "
      set -g status-right "#[fg=#a6e3a1] %H:%M  %d-%b-%Y "

      # Window titles
      set -g automatic-rename on
      set -g set-titles on
    '';
  };

  home.packages = [ pkgs.tmuxp ];
}
