# rclone cloud sync — systemd user services
# rclone.conf is an agenix secret; sync jobs are defined as systemd services.
{ pkgs, config, ... }:
{
  home.packages = [ pkgs.rclone ];

  # Deploy rclone config from agenix secret:
  # age.secrets.rclone = {
  #   file = ../../../secrets/rclone.age;
  #   owner = "frank";
  # };
  # home.file.".config/rclone/rclone.conf".source = config.age.secrets.rclone.path;

  # Example systemd user service for a sync job (replicate for each remote):
  # systemd.user.services."rclone-gdrive-sync" = {
  #   Unit.Description = "rclone sync: Google Drive → ~/GDrive";
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.rclone}/bin/rclone sync gdrive: ~/GDrive --config %h/.config/rclone/rclone.conf";
  #   };
  # };
  # systemd.user.timers."rclone-gdrive-sync" = {
  #   Timer = {
  #     OnCalendar = "hourly";
  #     Persistent = true;
  #   };
  #   Install.WantedBy = [ "timers.target" ];
  # };
}
