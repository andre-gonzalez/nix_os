# ThinkPad-specific power management. Import together with power.nix.
#
# Both settings here are enforced by the embedded controller rather than by
# software polling, so they survive suspend and poweroff. They reach the EC
# through natacpi — the in-tree thinkpad_acpi driver, which exposes
# /sys/class/power_supply/BAT*/charge_control_{start,end}_threshold.
# Neither tp-smapi nor acpi_call is needed on any ThinkPad still supported by
# a current kernel; tp-smapi in particular only ever covered pre-2013 models.
{ ... }:
{
  services.tlp.settings = {
    # Charging stops at STOP and only resumes once the battery falls below
    # START. The gap is hysteresis: without it the battery would micro-cycle
    # around the stop threshold. Capping around 80% markedly slows the
    # capacity loss that comes from holding a Li-ion cell at full charge.
    # Use `tlp fullcharge` for a one-off 100% charge before travelling.
    START_CHARGE_THRESH_BAT0 = 77;
    STOP_CHARGE_THRESH_BAT0 = 80;

    # Drives the EC's sustained and burst power limits (PPT), which constrain
    # everything the governor and EPP settings do above them. This is the
    # highest-leverage knob on a modern ThinkPad.
    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "balanced";
    PLATFORM_PROFILE_ON_SAV = "low-power";
  };

  # thinkpad_acpi provides natacpi (thresholds, fan, hotkeys).
  boot.kernelModules = [ "thinkpad_acpi" ];
}
