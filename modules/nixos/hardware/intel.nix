# Intel graphics and hardware video acceleration
# Mirrors roles/samsung_expert (intel-media-driver) and Intel-specific tuning
{ pkgs, ... }:
{
  # Intel microcode updates
  hardware.cpu.intel.updateMicrocode = true;

  # Intel VA-API hardware video acceleration (intel-media-driver on Arch)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver   # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver   # LIBVA_DRIVER_NAME=i965 (older GPUs)
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-vaapi-driver
    ];
  };

  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD";
    VDPAU_DRIVER = "va_gl";
  };

  # i915 kernel module options for better power management
  boot.kernelModules = [ "i915" ];
  boot.kernelParams = [
    "i915.enable_guc=2"           # GuC/HuC firmware
    "i915.enable_fbc=1"           # framebuffer compression
    "i915.enable_psr=1"           # panel self-refresh (saves battery)
  ];
}
