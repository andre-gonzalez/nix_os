# crash-notify — mirrors roles/light_workstation/tasks/crash-notify.yml
#
# Not optional: .xinitrc (dotfiles repo) runs `crash-notify &`, so a session
# without it logs a "command not found" on every startx.
#
# The watcher follows systemd-coredump's journal entries and raises a dunst
# notification per crash; its action opens st running Claude Code with the
# diagnose-crash skill. Same layout as on Arch: the scripts in ~/.local/bin,
# the skill in ~/.claude/skills. The scripts are copied verbatim from the
# Ansible role except for the default working directory (this repo, not the
# Ansible one); the skill is adapted for NixOS (no pacman.log, no Arch
# debuginfod).
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jq          # parses the journal's JSON entries
    libnotify   # notify-send, with --action support
    gdb         # used by the diagnose-crash skill to read the core
    claude-code # the notification action execs `claude`
  ];

  # Executable bits come from the files themselves (tracked as 0755 in git).
  home.file.".local/bin/crash-notify".source = ./crash-notify/crash-notify;
  home.file.".local/bin/crash-mute".source = ./crash-notify/crash-mute;

  home.file.".claude/skills/diagnose-crash/SKILL.md".source =
    ./crash-notify/diagnose-crash/SKILL.md;
}
