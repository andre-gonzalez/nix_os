# Mirrors roles/base/tasks/locale.yml and vconsole.conf
{ ... }:
{
  time.timeZone = "America/Sao_Paulo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS        = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
      LC_MEASUREMENT    = "pt_BR.UTF-8";
      LC_MONETARY       = "pt_BR.UTF-8";
      LC_NAME           = "pt_BR.UTF-8";
      LC_NUMERIC        = "pt_BR.UTF-8";
      LC_PAPER          = "pt_BR.UTF-8";
      LC_TELEPHONE      = "pt_BR.UTF-8";
      LC_TIME           = "pt_BR.UTF-8";
    };
  };

  # Dvorak keyboard layout in virtual console (mirrors /etc/vconsole.conf)
  console = {
    keyMap = "dvorak";
  };

  # Dvorak in X11 is handled in modules/nixos/desktop/xorg.nix
}
