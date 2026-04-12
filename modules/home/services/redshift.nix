# Redshift — color temperature / blue light filter
{ ... }:
{
  services.redshift = {
    enable = true;
    provider = "manual";
    latitude  = "-23.5";   # São Paulo
    longitude = "-46.6";
    temperature = {
      day   = 6500;
      night = 3500;
    };
    settings = {
      redshift = {
        fade = 1;
        gamma = "1.0";
      };
    };
  };
}
