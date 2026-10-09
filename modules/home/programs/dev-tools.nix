# CLI and development tools from roles/light_workstation/tasks/packages.yml
# (and neovim.yml) that had no home here yet.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # bat-extras: batman, batgrep, batdiff, batwatch, prettybat, batpipe
    bat-extras.batman
    bat-extras.batgrep
    bat-extras.batdiff
    bat-extras.batwatch
    bat-extras.prettybat
    bat-extras.batpipe

    shellcheck
    shfmt
    bash-language-server # neovim.yml
    ansible-lint

    postgresql # client tools (psql, pg_dump), as postgresql-libs on Arch; no server
    lnav       # log navigator
    _7zz       # 7-Zip (7zz), as the 7zip package on Arch; p7zip still provides 7z
  ];
}
