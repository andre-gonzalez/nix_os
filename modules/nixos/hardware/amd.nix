# AMD graphics and hardware video acceleration — Radeon 860M (Krackan Point iGPU)
#
# This is the AMD counterpart to hardware/intel.nix. The two are mutually
# exclusive: intel.nix sets LIBVA_DRIVER_NAME=iHD and i915.* kernel params
# globally, so an AMD host must import this one and NOT that one.
#
# nixos-hardware's common-gpu-amd module (wired in flake.nix) already sets
# services.xserver.videoDrivers = [ "modesetting" ], hardware.graphics.enable,
# hardware.graphics.enable32Bit and hardware.amdgpu.initrd.enable. This module
# adds only what it does not. radeonsi (VA-API) and RADV (Vulkan) ship inside
# mesa itself, so hardware.graphics.extraPackages needs nothing here.
# hardware.cpu.amd.updateMicrocode is set by hardware/power-amd.nix, which is
# imported alongside this module on every AMD host.
{ pkgs, ... }:
{
  environment.variables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };

  environment.systemPackages = with pkgs; [
    libva-utils # vainfo — verify radeonsi is picked up
    vulkan-tools # vulkaninfo / vkcube — verify RADV
    radeontop # GPU utilisation
  ];
}
