# Databricks CLI — roles/work/tasks/databricks.yml (inactive in Ansible, but
# the CLI and its config are in daily use on Arch). pkgs/databricks-cli pins
# the official 1.19.0 binary.
#
# ~/.databrickscfg (profiles) and ~/.databricks-connect are agenix secrets,
# seeded once: `databricks auth login` and `databricks configure` rewrite the
# first, so it must stay a writable file.
{ lib, customPkgs, ... }:
let
  seed = secret: target: ''
    if [ ! -e "$HOME/${target}" ] && [ -r /run/agenix/${secret} ]; then
      $DRY_RUN_CMD install -D -m 0600 /run/agenix/${secret} "$HOME/${target}"
    fi
  '';
in
{
  home.packages = [ customPkgs.databricks-cli ];

  home.activation.seedDatabricks = lib.hm.dag.entryAfter [ "writeBoundary" ]
    (seed "databrickscfg" ".databrickscfg" + seed "databricks-connect" ".databricks-connect");
}
