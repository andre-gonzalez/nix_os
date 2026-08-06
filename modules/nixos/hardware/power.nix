# TLP power management — notebook hosts only
# Mirrors roles/light_workstation/tasks/save-battery.yml
{ pkgs, ... }:
{
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      DISK_SPINDOWN_TIMEOUT_ON_AC = "0 0";
      DISK_SPINDOWN_TIMEOUT_ON_BAT = "0 1";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      NMI_WATCHDOG = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";
    };
  };

  # Disable power-profiles-daemon — conflicts with TLP
  services.power-profiles-daemon.enable = false;

  # Intel CPU voltage/frequency control (AUR: intel-undervolt)
  # Requires calibration per-machine; config placed at ~/.config/intel-undervolt.conf
  services.undervolt = {
    enable = false; # enable and tune per machine
    # core  = -80;   # mV undervolt on P-cores
    # cache = -80;
    # gpu   = -40;
  };

  environment.systemPackages = with pkgs; [
    powertop
    acpi
    acpid
  ];
}
