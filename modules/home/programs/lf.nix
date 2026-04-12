# lf file manager + lfub script (bat previews, image previews)
{ pkgs, ... }:
{
  programs.lf = {
    enable = true;

    settings = {
      preview  = true;
      hidden   = true;
      drawbox  = true;
      icons    = true;
      ignorecase = true;
    };

    commands = {
      # Open with appropriate program
      open = ''
        ''${{
          case $(file --mime-type "$f" -b) in
            text/*|application/json) $EDITOR "$f";;
            image/*) feh "$f";;
            video/*|audio/*) mpv "$f";;
            application/pdf) zathura "$f";;
            *) xdg-open "$f";;
          esac
        }}
      '';

      # Trash instead of delete
      delete = ''
        ''${{ trash-put "$fx" }}
      '';
    };

    keybindings = {
      "D" = "delete";
      "<enter>" = "open";
      "." = "set hidden!";
    };

    previewer = {
      keybinding = "i";
      source = pkgs.writeShellScript "lfpreviewer" ''
        #!/usr/bin/env bash
        case "$(file --mime-type -b "$1")" in
          text/*|application/json) bat --color=always --style=plain "$1";;
          image/*) chafa "$1";;
          video/*) ffmpegthumbnailer -i "$1" -o /tmp/thumb.png -s 0 && chafa /tmp/thumb.png;;
          *) file "$1";;
        esac
      '';
    };
  };

  home.packages = with pkgs; [
    bat
    chafa
    ffmpegthumbnailer
    file
    trash-cli
  ];
}
