# TLP power management — vendor-neutral settings, notebook hosts only.
# Mirrors roles/light_workstation/templates/tlp-local.conf.j2
#
# Import alongside exactly one CPU-vendor module:
#   power-amd.nix    — amd-pstate hosts
#   power-intel.nix  — intel_pstate hosts
# and, on Lenovo machines, power-thinkpad.nix for the EC-backed knobs.
#
# Keys are split across those modules rather than overridden with mkDefault:
# services.tlp.settings is an attrset, so two modules defining the same key
# would be a conflict, while disjoint key sets merge cleanly.
#
# TLP has three profiles: AC and BAT are selected automatically from the power
# source, SAV is manual (`tlp power-saver`, see ~/.scripts/power-saver).
{ pkgs, ... }:
{
  services.tlp = {
    enable = true;
    settings = {
      # Energy/performance preference. On drivers running in active mode this,
      # not the governor, is what differentiates AC from battery.
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";

      # Race-to-idle: bursting and dropping back to a deep idle state costs
      # less energy than crawling through the same work with the rest of the
      # SoC held awake. Boost stays enabled on battery.
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_BOOST_ON_SAV = 0;

      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersave";
      PCIE_ASPM_ON_SAV = "powersupersave";

      USB_AUTOSUSPEND = 1;

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      DEVICES_TO_DISABLE_ON_LAN_CONNECT = "wifi wwan";
      DEVICES_TO_ENABLE_ON_LAN_DISCONNECT = "wifi wwan";

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      NMI_WATCHDOG = 0;
    };
  };

  # tlp.service declares Conflicts=power-profiles-daemon.service. Whenever PPD
  # is running TLP never starts and none of the settings above are applied.
  services.power-profiles-daemon.enable = false;

  environment.systemPackages = with pkgs; [
    powertop
    acpi
    acpid
  ];
}
