# Zathura PDF viewer — set as XDG default for PDF in home/default.nix
{ ... }:
{
  programs.zathura = {
    enable = true;

    options = {
      # Catppuccin Mocha theme
      default-bg              = "#1e1e2e";
      default-fg              = "#cdd6f4";
      statusbar-bg            = "#181825";
      statusbar-fg            = "#cdd6f4";
      inputbar-bg             = "#1e1e2e";
      inputbar-fg             = "#cdd6f4";
      notification-bg         = "#1e1e2e";
      notification-fg         = "#cdd6f4";
      notification-error-bg   = "#1e1e2e";
      notification-error-fg   = "#f38ba8";
      notification-warning-bg = "#1e1e2e";
      notification-warning-fg = "#fab387";
      highlight-color         = "#f5c2e7";
      highlight-active-color  = "#cba6f7";
      recolor-lightcolor      = "#1e1e2e";
      recolor-darkcolor       = "#cdd6f4";
      recolor                 = true;

      # Behaviour
      adjust-open = "best-fit";
      pages-per-row = 1;
      scroll-page-aware = true;
      selection-clipboard = "clipboard";
      zoom-min = 10;
    };
  };
}
