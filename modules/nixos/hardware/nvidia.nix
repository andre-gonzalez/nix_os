# NVIDIA driver configuration
# Mirrors roles/nvidia — auto-selects open vs legacy driver
{ config, pkgs, ... }:
{
  # Use the open-source NVIDIA kernel module (Turing+ / RTX 20xx and newer)
  # For older GPUs, set `open = false` and pin the appropriate version below
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true; # set false for Maxwell/Pascal/pre-Turing
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      nvidia-vaapi-driver
    ];
  };

  # GPU switching utility (AUR: envycontrol)
  environment.systemPackages = [ pkgs.envycontrol ];
}
