# TLP settings specific to amd-pstate hosts. Import together with power.nix.
{ ... }:
{
  services.tlp.settings = {
    # Keep amd-pstate in active mode (amd-pstate-epp) on every profile.
    # Switching opmode between profiles re-registers all cpufreq policies on a
    # live system, and silently disables EPP and MIN/MAX_PERF on the passive
    # side — which is where a mixed active/passive config quietly loses most
    # of its tuning.
    CPU_DRIVER_OPMODE_ON_AC = "active";
    CPU_DRIVER_OPMODE_ON_BAT = "active";
    CPU_DRIVER_OPMODE_ON_SAV = "active";

    # In active mode "performance" pins the CPU to maximum permanently; it is
    # not a "prefer speed" hint. Use powersave on every profile and steer with
    # CPU_ENERGY_PERF_POLICY_* from power.nix instead.
    CPU_SCALING_GOVERNOR_ON_AC = "powersave";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_SCALING_GOVERNOR_ON_SAV = "powersave";

    # Adaptive Backlight Management on the internal panel: dims the backlight
    # and compensates by boosting pixel values. Real savings, but a visible
    # contrast/colour shift — set the BAT level to 0 for colour-sensitive work.
    # Requires /sys/class/drm/card*-eDP-*/amdgpu/panel_power_savings.
    AMDGPU_ABM_LEVEL_ON_AC = 0;
    AMDGPU_ABM_LEVEL_ON_BAT = 2;
    AMDGPU_ABM_LEVEL_ON_SAV = 3;
  };

  hardware.cpu.amd.updateMicrocode = true;
}
