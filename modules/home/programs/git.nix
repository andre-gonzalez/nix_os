# git identity + delta pager
{ pkgs, ... }:
{
  programs.git = {
    enable = true;

    userName  = "André Gonzalez";
    userEmail = "lopescg@gmail.com";

    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Catppuccin-mocha";
        features = "line-numbers decorations";
      };
    };

    extraConfig = {
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      rerere.enabled = true;

      # Sign commits with SSH key (optional, uncomment when ready)
      # gpg.format = "ssh";
      # user.signingKey = "~/.ssh/id_ed25519.pub";
      # commit.gpgsign = true;
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      ".env"
      ".direnv/"
      "result"
    ];
  };
}
