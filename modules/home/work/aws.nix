# AWS CLI v2 + credentials from agenix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awscli2
    # awsvpnclient is not in nixpkgs; use the official installer or wrap as AppImage:
    # (callPackage ../../../pkgs/awsvpnclient { })
  ];

  # AWS credentials deployed from agenix secret:
  # age.secrets.aws-credentials = {
  #   file = ../../../secrets/aws-credentials.age;
  #   owner = "frank";
  # };
  # home.file.".aws/credentials".source = config.age.secrets.aws-credentials.path;

  # AWS config (non-secret — region, output format)
  home.file.".aws/config".text = ''
    [default]
    region = eu-west-1
    output = json
  '';
}
