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

    # The *client* tools only — pactl, pacmd, pa-info. services.pulseaudio is
    # off above; these talk to pipewire-pulse, and the dotfiles' .xbindkeysrc
    # binds the XF86Audio* keys to `pactl`, which is otherwise absent (pipewire
    # ships wpctl, and NixOS does not pull the pulse CLI in on its own).
    pulseaudio
    playerctl  # XF86AudioPlay/Next/Prev via MPRIS, also from .xbindkeysrc
  ];
}
