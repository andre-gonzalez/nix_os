# Former crontab entries — mirrors roles/light_workstation/tasks/cron.yml,
# as systemd user services + timers (no cron daemon on this system).
#
# The scripts themselves live in ~/.scripts (modules/home/scripts.nix). They
# were written for cron's bare environment and export DISPLAY / DBUS themselves,
# so the units only have to supply a PATH.
#
# Errors still go to ~/.cron-errors/<job>-error-logs.txt rather than only the
# journal: the dwm_cron dwmblocks block counts the non-empty files there.
#
# Not ported: the ansible-pull job (disabled in Ansible, meaningless here).
{ pkgs, ... }:
let
  # What a login shell would see. %h is expanded by systemd.
  path = builtins.concatStringsSep ":" [
    "/run/wrappers/bin"
    "/etc/profiles/per-user/frank/bin"
    "/run/current-system/sw/bin"
    "%h/.scripts"
    "%h/.local/bin"
  ];

  errLog = name: "append:%h/.cron-errors/${name}-error-logs.txt";
in
{
  systemd.user.tmpfiles.rules = [ "d %h/.cron-errors 0700 - - -" ];

  systemd.user.services = {
    # @reboot DISPLAY=:0 ~/.scripts/profile-selector
    # Starts with the user manager (tty1 autologin), before X exists; the script
    # itself waits for dwm, dbus and PipeWire. Type=exec, not oneshot: a oneshot
    # pulled in by default.target would hold up the user manager's startup —
    # and with it the login that is supposed to run startx — until dwm appears.
    # KillMode=process because it launches the work/pessoal session programs,
    # which must outlive the script.
    profile-selector = {
      Unit.Description = "Choose work/personal profile after login";
      Service = {
        Type = "exec";
        Environment = [ "PATH=${path}" "DISPLAY=:0" ];
        ExecStart = "%h/.scripts/profile-selector";
        KillMode = "process";
      };
      Install.WantedBy = [ "default.target" ];
    };

    # @reboot sleep 60 && rm -r ~/Downloads, and again every 10 minutes.
    remove-downloads = {
      Unit.Description = "Delete ~/Downloads";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/rm -rf %h/Downloads";
      };
    };

    # */10 * * * * /bin/sh ~/.scripts/push-new-notes.sh
    push-new-notes = {
      Unit.Description = "Commit and push the notes repository";
      Service = {
        Type = "oneshot";
        Environment = [ "PATH=${path}" ];
        ExecStart = "/bin/sh %h/.scripts/push-new-notes.sh";
        StandardError = errLog "push-new-notes";
      };
    };

    # */5 19-20,6-15 * * *  (ran as root on Arch; brightnessctl's udev rules
    # plus the video group make that unnecessary — see desktop/xorg.nix)
    auto-adjust-brightness = {
      Unit.Description = "Step screen brightness down in the evening";
      Service = {
        Type = "oneshot";
        Environment = [ "PATH=${path}" ];
        ExecStart = "/bin/sh %h/.scripts/auto-adjust-brightness.sh";
        StandardError = errLog "auto-adjust-brightness";
      };
    };
  };

  systemd.user.timers = {
    remove-downloads = {
      Unit.Description = "Delete ~/Downloads a minute after login and every 10 minutes";
      Timer = {
        OnStartupSec = "1min";
        OnUnitActiveSec = "10min";
      };
      Install.WantedBy = [ "timers.target" ];
    };

    push-new-notes = {
      Unit.Description = "Sync the notes repository every 10 minutes";
      Timer = {
        OnCalendar = "*:0/10";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    auto-adjust-brightness = {
      Unit.Description = "Adjust screen brightness every 5 minutes, 06–15h and 19–20h";
      Timer.OnCalendar = "*-*-* 06..15,19..20:00/5:00";
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
