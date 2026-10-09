# Working copies that the session depends on — mirrors
# roles/light_workstation/tasks/{dotfiles,notas,directory}.yml.
#
# Same bargain as ~/.scripts (scripts.nix): the content is imperative and gets
# edited and pushed in place, so it is a clone, not a store path. Activation
# only creates what is missing and never touches an existing checkout. It runs
# at boot too, when the network may not be up yet, so a failed clone only
# warns; the next rebuild retries.
{ config, lib, pkgs, ... }:
let
  git = "${pkgs.git}/bin/git";
  home = config.home.homeDirectory;
  dotfiles = "${home}/.config/dotfiles";
in
{
  # tasks/directory.yml
  systemd.user.tmpfiles.rules = [
    "d %h/projects 0770 - - -"
    "d %h/gdrive-pessoal/not-up/iso 0770 - - -"
  ];

  # Bare dotfiles repo, checked out over $HOME (.xinitrc, .xbindkeysrc, lf,
  # autorandr profiles, gtk settings.ini, git config, …). Public, so cloned
  # over HTTPS before any ssh key exists; the push URL is ssh. `checkout -f`
  # as in the Ansible handler: on a first clone the repo wins. No file in it
  # is also written by home-manager, so the two cannot fight.
  home.activation.cloneDotfiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -e "${dotfiles}" ]; then
      if $DRY_RUN_CMD ${git} clone --quiet --bare \
           https://github.com/andre-gonzalez/dotfiles.git "${dotfiles}"; then
        dot() { $DRY_RUN_CMD ${git} --git-dir="${dotfiles}" --work-tree="${home}" "$@"; }
        dot config status.showUntrackedFiles no
        dot remote set-url --push origin git@github.com:andre-gonzalez/dotfiles.git
        dot checkout -f
      else
        echo "warning: could not clone the dotfiles repo; retrying on next rebuild"
      fi
    fi
  '';

  # Notes vault: ~/.scripts (todo, add-bookmark, open-file, …), stw's keybind
  # overlay and the push-new-notes timer all read it. Private, so it needs the
  # ssh key from user-secrets.nix; it is passed explicitly because activation
  # has no agent, and github's host key is accepted on first use.
  home.activation.cloneNotas = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -e "${home}/projects/notas" ]; then
      key="${home}/.ssh/personal_id_ed25519_2023-11"
      if [ -r "$key" ] && GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i $key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
           $DRY_RUN_CMD ${git} clone --quiet \
             git@github.com:andre-gonzalez/notas.git "${home}/projects/notas"; then
        :
      else
        echo "warning: could not clone notas (ssh key or network missing); retrying on next rebuild"
      fi
    fi
  '';
}
