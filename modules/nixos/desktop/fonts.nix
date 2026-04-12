# Mirrors font packages from roles/light_workstation
{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      # Noto family (mirrors noto-fonts-* on Arch)
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-extra

      # Liberation fonts (ttf-liberation on Arch)
      liberation_ttf

      # DejaVu
      dejavu_fonts

      # Linux Libertine (ttf-linux-libertine on Arch)
      linux-libertine

      # Nerd Fonts symbols (ttf-nerd-fonts-symbols on Arch)
      (nerdfonts.override { fonts = [
        "NerdFontsSymbolsOnly"
        "JetBrainsMono"
        "FiraCode"
        "Hack"
      ]; })

      # JoyPixels emoji (ttf-joypixels on Arch)
      joypixels

      # Additional
      font-awesome
    ];

    fontconfig = {
      defaultFonts = {
        serif      = [ "Linux Libertine" "Noto Serif" ];
        sansSerif  = [ "Noto Sans" "Liberation Sans" ];
        monospace  = [ "JetBrainsMono Nerd Font" "Hack Nerd Font" ];
        emoji      = [ "JoyPixels" "Noto Color Emoji" ];
      };
    };
  };
}
