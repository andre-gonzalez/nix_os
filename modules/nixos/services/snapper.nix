# Snapper is configured in hardware/btrfs.nix.
# This module is a thin re-export kept for clean host imports.
{ ... }:
{
  imports = [ ../hardware/btrfs.nix ];
}
