# AWS CLI v2 — mirrors roles/work/tasks/aws.yml.
#
# Access is AWS SSO now: on Arch ~/.aws holds only `config` (SSO profiles)
# plus the sso/ token cache, and no `credentials` file — the vaulted
# credentials-aws/config-aws in Ansible predate that and are not used.
# ~/.aws/config is the agenix secret "aws-config" (account ids, SSO start
# URL), seeded once and then left to `aws configure sso` to edit.
{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.awscli2 ];

  home.activation.seedAwsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.aws/config" ] && [ -r /run/agenix/aws-config ]; then
      $DRY_RUN_CMD install -D -m 0600 /run/agenix/aws-config "$HOME/.aws/config"
    fi
  '';
}
