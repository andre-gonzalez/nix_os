# dwmblocks-async — the status bar dwm actually runs
# (github.com/andre-gonzalez/dwmblocks-async; roles/light_workstation/tasks/dwmblocks.yml
# built this repo, not the older andre-gonzalez/dwmblocks this file used to point at).
#
# The binary's config.h calls ~17 `dwm_*` helpers by bare name. Upstream's
# `make install` copies the shell ones into PREFIX/bin but only *symlinks* the
# compiled ones back into the build tree, which does not survive in the store —
# so the install phase is written out here instead. Which helper is which is
# read from the Makefile's own BAR_NAMES / BAR_SHELL lists, so a block added
# upstream is picked up on the next rev bump.
#
# Every helper is wrapped with the tools it needs: dwmblocks spawns blocks with
# whatever PATH the X session inherited, and a block that cannot find its tool
# prints nothing rather than complaining. dwmblocks itself is wrapped with its
# own bin/ for the same reason.
#
# Known Arch-isms upstream, left alone rather than patched into divergence:
# dwm_packages (pacman's checkupdates) and dwm_ufw (`sudo ufw`) render nothing.
{ stdenv, lib, fetchFromGitHub, makeWrapper, pkg-config
, libxcb, libxcb-util, systemd
, coreutils, gnugrep, gnused, gawk, findutils, procps, util-linux
, iproute2, iw, iwd, bluez, playerctl, pamixer, pulseaudio, brightnessctl
, libnotify, btrfs-progs, curl, jq, dbus, xclip, ncdu, tmux
}:
let
  # Union of every external command the helpers and the bluetooth watcher call.
  runtimeDeps = [
    coreutils gnugrep gnused gawk findutils procps util-linux
    iproute2 iw iwd bluez playerctl pamixer pulseaudio brightnessctl
    libnotify btrfs-progs curl jq dbus xclip ncdu tmux
  ];
in
stdenv.mkDerivation {
  pname = "dwmblocks-async";
  version = "unstable-2026-09-17";

  src = fetchFromGitHub {
    owner = "andre-gonzalez";
    repo = "dwmblocks-async";
    rev = "c33a41fd94926b00ae5458de1f451787964907ff";
    hash = "sha256-KOs8F/zOWkL2KxtYOtW/J01njd8rddmZ2mOZ4ROQrrQ=";
  };

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ libxcb libxcb-util systemd ];

  # dwm_currency sources its config from next to itself, which in the store is
  # a read-only path nobody can write to. Read it from ~/.config/dwmblocks/,
  # where the per-machine file already lives, and keep the upstream defaults
  # when it is absent (a failed `.` would kill the block outright).
  postPatch = ''
    substituteInPlace bar-functions/dwm_currency \
      --replace-fail '. "''${0%/*}/dwm_currency.conf"' \
        'conf="''${XDG_CONFIG_HOME:-$HOME/.config}/dwmblocks/dwm_currency.conf"; [ -r "$conf" ] && . "$conf"'
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 build/dwmblocks $out/bin/dwmblocks

    vars() { make -s --no-print-directory --eval 'print-%: ; @echo $($*)' "print-$1"; }

    for name in $(vars BAR_NAMES); do        # compiled helpers (<name>_c)
      install -Dm755 "bar-functions/''${name}_c" "$out/bin/$name"
    done
    for name in $(vars BAR_SHELL); do        # shell helpers
      install -Dm755 "bar-functions/$name" "$out/bin/$name"
    done
    install -Dm755 services/dwmblocks-bluetooth $out/bin/dwmblocks-bluetooth

    patchShebangs $out/bin
    for f in $out/bin/dwm_* $out/bin/dwmblocks-bluetooth; do
      wrapProgram "$f" --prefix PATH : ${lib.makeBinPath runtimeDeps}
    done
    wrapProgram $out/bin/dwmblocks --prefix PATH : "$out/bin"

    runHook postInstall
  '';

  meta = {
    description = "Asynchronous modular status bar for dwm (personal fork)";
    homepage = "https://github.com/andre-gonzalez/dwmblocks-async";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "dwmblocks";
  };
}
