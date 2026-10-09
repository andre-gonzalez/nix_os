# roles/light_workstation/tasks/security.yml: ClamAV with its daemon and
# signature updates (both running on Arch). Not in base: clamd keeps its
# signature database in memory (about 1 GiB), too much for a small server VM.
{ ... }:
{
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };
}
