# dwmblocks — modular status bar for dwm
#
# Upstream's `make install` copies *only* the dwmblocks binary, but the binary's
# compiled-in config.h shells out to thirteen `dwm_*` helpers that live in the
# repo's bar-functions/ directory. On Arch that gap was papered over by a manual
# `sudo make install` that had, at some point, dropped those helpers into
# /usr/local/bin; on NixOS there is no such leftover, so every block ran a
# command that did not exist and the bar came up empty. Hence the postInstall
# below: the helpers ship in the same output as the binary that calls them.
#
# The helpers are wrapped rather than merely copied because a status block is
# spawned by dwmblocks with whatever PATH the X session happened to inherit —
# on a graphical login, close to nothing. Wrapping pins the tools each needs.
{ stdenv, lib, makeWrapper, libx11
, coreutils, gnugrep, gnused, gawk, findutils, procps
, iproute2, iw, iwd, bluez, playerctl, pamixer, brightnessctl, dunst
, libnotify, btrfs-progs
}:
let
  # Union of every external command reachable from the blocks listed in
  # config.h. Kept as one list rather than per-script: the scripts are upstream
  # content that changes without notice, and a missing entry fails silently —
  # a block that cannot find its tool prints nothing rather than complaining.
  runtimeDeps = [
    coreutils gnugrep gnused gawk findutils procps
    iproute2 iw iwd bluez playerctl pamixer brightnessctl dunst
    libnotify btrfs-progs
  ];
in
stdenv.mkDerivation {
  pname = "dwmblocks";
  version = "unstable";

  src = builtins.fetchGit {
    url = "https://github.com/andre-gonzalez/dwmblocks.git";
    ref = "main";
    rev = "14e1110b408fc97c1fb32c2f84515eeb8eca377f";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ libx11 ];

  makeFlags = [ "PREFIX=$(out)" ];
  preBuild = "make clean"; # upstream commits a prebuilt generic-Linux binary; force a real recompile

  # The T14's battery enumerates as BAT0, but the script hardcodes the BAT1 of
  # the machine it was written on and then does integer comparisons on the
  # empty string it reads back. Patched here rather than upstream because the
  # node name is a fact about this hardware, not about the script: globbing
  # keeps it right on whatever the next machine calls its battery.
  postPatch = ''
    substituteInPlace bar-functions/dwm_battery \
      --replace-fail 'BAT="BAT1"' \
        'BAT=$(basename "$(echo /sys/class/power_supply/BAT* | cut -d" " -f1)")'
  '';

  postInstall = ''
    for f in bar-functions/dwm_*; do
      # Skip the C sources and sample configs sitting alongside the helpers.
      case "$f" in *.c|*.conf.example) continue ;; esac

      # config.h calls the helpers by bare name — `dwm_systemd_networkd`, not
      # `dwm_systemd_networkd.sh` — so the extension is dropped on install.
      name=$(basename "$f" .sh)
      install -Dm755 "$f" "$out/bin/$name"
      patchShebangs "$out/bin/$name"
      wrapProgram "$out/bin/$name" \
        --prefix PATH : ${lib.makeBinPath runtimeDeps}
    done

    # dwmblocks itself is started from .xinitrc, where PATH is whatever the X
    # session inherited; pinning its own bin/ means the blocks resolve even if
    # this package never made it onto the interactive PATH.
    wrapProgram "$out/bin/dwmblocks" --prefix PATH : "$out/bin"
  '';

  meta = {
    description = "modular status bar for dwm";
    homepage    = "https://github.com/andre-gonzalez/dwmblocks";
    license     = lib.licenses.mit;
    platforms   = lib.platforms.linux;
  };
}
