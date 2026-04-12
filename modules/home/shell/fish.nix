# Fish shell user config — mirrors oh-my-fish setup and shell aliases
{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    shellAliases = {
      # Editor
      v   = "nvim";
      vi  = "nvim";
      vim = "nvim";

      # ls replacements
      ls  = "ls --color=auto";
      ll  = "ls -lah --color=auto";
      la  = "ls -A --color=auto";

      # Git
      g   = "git";
      ga  = "git add";
      gc  = "git commit";
      gco = "git checkout";
      gd  = "git diff";
      gl  = "git log --oneline --graph --decorate";
      gp  = "git push";
      gs  = "git status";

      # Dotfiles bare repo (Option A — keep until migrated to HM)
      dots = "git --git-dir=$HOME/.config/dotfiles/ --work-tree=$HOME";

      # Safety aliases
      cp  = "cp -i";
      mv  = "mv -i";
      rm  = "rm -i";

      # Misc
      grep  = "grep --color=auto";
      df    = "df -h";
      du    = "du -h";
      free  = "free -h";
      reload = "source ~/.config/fish/config.fish";
    };

    shellInit = ''
      # Starship prompt (or pure prompt)
      # starship init fish | source

      # zoxide
      zoxide init fish | source

      # fzf key bindings
      fzf --fish | source
    '';

    functions = {
      mkcd = ''
        mkdir -p $argv[1] && cd $argv[1]
      '';

      # Extract any archive
      ex = ''
        switch $argv[1]
          case "*.tar.bz2";  tar xjf $argv[1]
          case "*.tar.gz";   tar xzf $argv[1]
          case "*.tar.xz";   tar xJf $argv[1]
          case "*.tar.zst";  tar xaf $argv[1]
          case "*.bz2";      bunzip2 $argv[1]
          case "*.gz";       gunzip $argv[1]
          case "*.tar";      tar xf $argv[1]
          case "*.tbz2";     tar xjf $argv[1]
          case "*.tgz";      tar xzf $argv[1]
          case "*.zip";      unzip $argv[1]
          case "*.7z";       7z x $argv[1]
          case "*";          echo "'$argv[1]' cannot be extracted via ex"
        end
      '';
    };
  };
}
