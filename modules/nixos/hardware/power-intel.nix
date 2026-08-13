# TLP settings specific to intel_pstate hosts. Import together with power.nix.
#
# These values preserve the behaviour the Ansible role has always applied to
# the Samsung Expert. Note that the amd-pstate reasoning in power-amd.nix about
# the "performance" governor applies to intel_pstate in active mode too: it
# pins the CPU to maximum rather than merely preferring speed. Left as-is here
# because changing it is a retune of that machine, not a correctness fix.
{ ... }:
{
  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_SCALING_GOVERNOR_ON_SAV = "powersave";

    # HWP dynamic boost is an intel_pstate feature; it is a no-op on AMD and so
    # is deliberately absent from power-amd.nix.
    CPU_HWP_DYN_BOOST_ON_AC = 1;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;

    SCHED_POWERSAVE_ON_AC = 0;
    SCHED_POWERSAVE_ON_BAT = 1;
  };

  # Intel CPU voltage/frequency control (AUR: intel-undervolt).
  # Requires calibration per-machine before enabling.
  services.undervolt = {
    enable = false;
    # core  = -80;   # mV undervolt on P-cores
    # cache = -80;
    # gpu   = -40;
  };
}
