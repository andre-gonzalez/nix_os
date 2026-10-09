# stw — text-in-window OSD (github.com/sineemore/stw), used by
# ~/.scripts/show_keybinds.sh. Mirrors roles/light_workstation/tasks/stw.yml,
# which built upstream master; nixpkgs' own stw stops at 2022-02-04, before
# clickthrough support, which added an Xfixes/shape dependency and moved the
# build to pkg-config.
{ stw, fetchFromGitHub, pkg-config, libxfixes, libxext }:
stw.overrideAttrs (old: {
  version = "unstable-2024-11-25";
  src = fetchFromGitHub {
    owner = "sineemore";
    repo = "stw";
    rev = "fa09dcc95499eccb77ff82c39d08e9f6aadf9e8a"; # master
    hash = "sha256-LpnZOJ6ybXXt3qLFoPFCOAes9RIcpW9EPD9Y37tP1fI=";
  };
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkg-config ];
  buildInputs = old.buildInputs ++ [ libxfixes libxext ];
})
