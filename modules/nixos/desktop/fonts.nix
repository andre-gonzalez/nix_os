# Mirrors font packages from roles/light_workstation
{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      # Noto family (mirrors noto-fonts-* on Arch)
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji   # was noto-fonts-emoji (renamed)
      # noto-fonts-extra was dropped from nixpkgs

      # Liberation fonts (ttf-liberation on Arch)
      liberation_ttf

      # DejaVu
      dejavu_fonts

      # Linux Libertine (ttf-linux-libertine on Arch)
      libertine                # was linux-libertine (renamed)

      # Nerd Fonts — nerdfonts.override was replaced by split nerd-fonts.* pkgs
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack

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
