{ inputs, customPkgs, pkgs, ... }:
{
  imports = [
    ./shell/fish.nix
    ./shell/tmux.nix

    ./desktop/dwm.nix
    ./desktop/st.nix
    ./desktop/dmenu.nix
    ./desktop/slock.nix
    ./desktop/dwmblocks.nix
    ./desktop/picom.nix
    ./desktop/dunst.nix
    ./desktop/feh.nix
    ./desktop/xbindkeys.nix

    ./programs/neovim.nix
    ./programs/git.nix
    ./programs/zathura.nix
    ./programs/mpv.nix
    ./programs/qutebrowser.nix
    ./programs/newsboat.nix
    ./programs/lf.nix
    ./programs/anki.nix
    ./programs/calibre.nix
    ./programs/zoxide.nix

    ./work/neomutt.nix
    ./work/aws.nix
    ./work/datagrip.nix
    ./work/cursor.nix
    ./work/onepassword.nix
    ./work/slack.nix

    ./services/redshift.nix
    ./services/rclone.nix
    ./services/syncthing.nix
  ];

  home = {
    username = "frank";
    homeDirectory = "/home/frank";
    stateVersion = "25.05"; # set once, do not update
  };

  # Keep dotfiles bare git repo working (Option A from migration plan)
  # The .xinitrc, .config/dwm, etc. continue to be managed by the bare repo
  # until they are incrementally migrated into Home Manager modules.
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PERSONAL_EMAIL = "lopescg@gmail.com";
  };

  # XDG MIME defaults (mirrors light_workstation xdg-mime calls)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png"  = [ "feh.desktop" ];
      "image/jpeg" = [ "feh.desktop" ];
      "image/gif"  = [ "feh.desktop" ];
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "impress.desktop" ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "writer.desktop" ];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "calc.desktop" ];
    };
  };
}
