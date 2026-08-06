# Mirrors roles/light_workstation/tasks/audio.yml — Pipewire + wireplumber
{ pkgs, ... }:
{
  # Disable PulseAudio — Pipewire provides the pulse compat layer
  services.pulseaudio.enable = false;

  security.rtkit.enable = true; # needed for real-time scheduling in Pipewire

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pamixer    # CLI volume control (AUR: pamixer)
    pavucontrol
    noisetorch  # noise suppression (AUR: noisetorch-bin)
  ];
}
