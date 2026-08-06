# Docker daemon — mirrors roles/docker
{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # frank needs to be in the docker group (also set in users.nix)
  users.users.frank.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
