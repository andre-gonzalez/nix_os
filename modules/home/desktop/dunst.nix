# dunst notification daemon
{ ... }:
{
  services.dunst = {
    enable = true;

    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        width = 300;
        height = 300;
        origin = "top-right";
        offset = "10x50";
        scale = 0;
        notification_limit = 0;
        progress_bar = true;
        indicate_hidden = true;
        transparency = 10;
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        text_icon_padding = 0;
        frame_width = 2;
        frame_color = "#89b4fa";
        separator_color = "frame";
        sort = true;
        idle_threshold = 120;
        font = "JetBrainsMono Nerd Font 10";
        line_height = 0;
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        ellipsize = "middle";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;
        icon_position = "left";
        min_icon_size = 0;
        max_icon_size = 32;
        sticky_history = true;
        history_length = 20;
        browser = "/usr/bin/env xdg-open";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        corner_radius = 4;
        ignore_dbusclose = false;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };

      urgency_low = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        timeout = 5;
      };

      urgency_normal = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        timeout = 10;
      };

      urgency_critical = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        frame_color = "#f38ba8";
        timeout = 0;
      };
    };
  };
}
