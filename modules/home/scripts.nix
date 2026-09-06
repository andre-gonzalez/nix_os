# ~/.scripts — github.com/andre-gonzalez/linux-scripts
#
# Not optional plumbing: .xinitrc runs random-wallpaper.sh from here,
# .xbindkeysrc binds keys to dwm_volume_show and kill-xautolock.sh, and both
# fish (fish_user_paths) and .bashrc put the directory on PATH. A machine
# without it has silently dead keybindings and no wallpaper — which is exactly
# what happened on the first t14-remote install, because ~/.scripts is not part
# of the dotfiles bare repo.
#
# Deliberately a *clone* rather than home.file + fetchFromGitHub: the working
# copy is edited in place and pushed back (it usually carries local
# modifications), which a read-only /nix/store symlink cannot support. That
# makes this the same "Option A" bargain as the dotfiles repo — imperative
# content, declarative that it is there.
#
# Cloned over HTTPS so it works before any ssh key exists on the machine; the
# push URL is then pointed at ssh, so `git push` from ~/.scripts still uses the
# key once one is present.
{ lib, pkgs, ... }:
let
  repo = "andre-gonzalez/linux-scripts";
  git = "${pkgs.git}/bin/git";
in
{
  home.activation.cloneScripts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.scripts" ]; then
      if $DRY_RUN_CMD ${git} clone --quiet \
           "https://github.com/${repo}.git" "$HOME/.scripts"; then
        $DRY_RUN_CMD ${git} -C "$HOME/.scripts" remote set-url --push origin \
          "git@github.com:${repo}.git"
      else
        # Activation runs at boot, where the network may not be up yet. Never
        # fail the whole activation over this — the guard above retries it on
        # the next rebuild.
        echo "warning: could not clone ${repo} into ~/.scripts; retrying on next rebuild"
      fi
    fi
  '';
}
