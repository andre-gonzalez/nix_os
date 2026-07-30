# Periodic TRIM — but only on machines whose root disk is an SSD/NVMe.
#
# Nix evaluation cannot look at the hardware it is building for (and these
# configs are built/installed remotely via nixos-anywhere), so "is this an SSD?"
# has to be answered at runtime on the target machine. We therefore always ship
# fstrim.timer and attach an ExecCondition to fstrim.service that inspects the
# rotational flag of the device backing /:
#
#   rotational = 0  -> SSD/NVMe  -> condition passes, fstrim runs
#   rotational = 1  -> spinning  -> condition fails, unit is skipped (NOT failed)
#
# A failing ExecCondition makes systemd skip the remaining commands without
# marking the unit failed, so HDD-only hosts simply log "skipping" once a week.
{ pkgs, ... }:
let
  # Exits 0 only when / lives on a non-rotational device.
  rootIsSSD = pkgs.writeShellScript "fstrim-root-is-ssd" ''
    set -euo pipefail

    # findmnt reports btrfs sources as "/dev/sda3[/@]" — strip the subvolume.
    src=$(${pkgs.util-linux}/bin/findmnt --noheadings --output SOURCE --target /)
    src=''${src%%\[*}

    # ROTA is resolved through partitions and dm layers (LUKS, LVM), so this
    # works for the plain-partition, encrypted and mapped cases alike.
    rota=$(${pkgs.util-linux}/bin/lsblk --nodeps --noheadings --output ROTA "$src" \
      | ${pkgs.coreutils}/bin/tr -d '[:space:]' || true)

    case "$rota" in
      0) echo "root device $src is non-rotational (SSD/NVMe) — trimming"; exit 0 ;;
      1) echo "root device $src is rotational (HDD) — skipping fstrim"; exit 1 ;;
      *) echo "could not read rotational flag of $src — skipping fstrim"; exit 1 ;;
    esac
  '';
in
{
  # nixpkgs already defaults this to true; set it explicitly so the intent is
  # visible next to the gate below.
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # util-linux ships fstrim.service, so this becomes a drop-in
  # (overrideStrategy defaults to "asDropinIfExists") rather than replacing it.
  #
  # NOTE: the gate looks at the root disk only. On a host with an SSD root plus
  # a spinning data disk, fstrim still runs — harmless, since the upstream unit
  # passes --quiet-unsupported and non-TRIM devices are just skipped. A machine
  # that boots from an HDD gets no trim at all, even if a secondary SSD exists.
  systemd.services.fstrim.serviceConfig.ExecCondition = [ "${rootIsSSD}" ];
}
