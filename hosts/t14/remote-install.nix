# `t14`, adapted for an unattended nixos-anywhere install over ssh.
#
# Exposed as the flake output .#t14-remote. It exists so that installing onto a
# borrowed/test machine never has to edit — and risk committing changes to — the
# real t14 host. Everything in hosts/t14/default.nix still applies except what an
# unattended install on foreign hardware cannot satisfy.
#
# See hosts/t14/INSTALL.md §6 for the full runbook.
#
# ── Current target ──────────────────────────────────────────────────────────
# 192.168.10.215 — Intel i7-8750H (Coffee Lake H), 31 GiB RAM, UHD 630 iGPU +
# GeForce GTX 1060 Mobile (Optimus), Kingston SA400S37 240G SATA SSD, Killer
# E2400 ethernet + Intel CNVi WiFi, UEFI. NOT a ThinkPad and NOT AMD, hence the
# module surgery below.
{ lib, ... }:
{
  imports = [
    ./default.nix
    ./hardware-configuration.remote.nix

    # Intel counterparts to the AMD/ThinkPad modules disabled just below.
    ../../modules/nixos/hardware/intel.nix
    ../../modules/nixos/hardware/power-intel.nix
  ];

  # amd.nix and intel.nix are mutually exclusive by construction (both set
  # LIBVA_DRIVER_NAME and VDPAU_DRIVER, which would collide), so the AMD half
  # has to be removed rather than overridden. power-thinkpad.nix drives EC
  # charge thresholds and ACPI platform profiles through thinkpad_acpi, which
  # this machine does not have.
  disabledModules = [
    ../../modules/nixos/hardware/amd.nix
    ../../modules/nixos/hardware/power-amd.nix
    ../../modules/nixos/hardware/power-thinkpad.nix
  ];

  #############################################################################
  # ⚠️  The disk that gets erased. /dev/sdb is the installer USB — leave it be.
  #############################################################################
  disko.devices.disk.main.device = lib.mkForce "/dev/sda";

  #############################################################################
  # 1. LUKS passphrase. cryptsetup has no tty over ssh, so disko reads it from a
  #    file that nixos-anywhere ships with --disk-encryption-keys. The file
  #    lands in the installer's tmpfs only; it is never copied to the target.
  #############################################################################
  local.diskoLuks.passwordFile = "/tmp/luks.key";

  #############################################################################
  # 2. No single-prompt initrd keyfile. boot.initrd.secrets is resolved during
  #    nixos-install, before --extra-files are copied into /mnt, so
  #    /boot/crypto_keyfile.bin cannot exist in time and the bootloader step
  #    would abort. Cost: one extra passphrase prompt at boot (GRUB, then initrd).
  #############################################################################
  local.diskoLuks.useInitrdKeyFile = false;

  #############################################################################
  # 3. No agenix. secrets/iwd-QUEWIFI-5G.age is encrypted to the t14 host key
  #    (secrets/secrets.nix); the target generates its own, different key, so
  #    activation would fail on every boot. Join WiFi with `iwctl` instead.
  #############################################################################
  age.secrets = lib.mkForce { };

  #############################################################################
  # 4. No fingerprint reader on this machine. Left enabled, pam_fprintd is
  #    consulted first on every sudo and stalls until it times out. The
  #    security.pam.services.slock *entry* must survive though — it is what
  #    creates /etc/pam.d/slock, and the slock fork opens that service by name
  #    (pam_service = "slock"); without the file the lock screen cannot
  #    authenticate at all and the session is unrecoverable. So set the option
  #    to false rather than removing it.
  #############################################################################
  services.fprintd.enable = lib.mkForce false;
  security.pam.services.sudo.fprintAuth = lib.mkForce false;
  security.pam.services.slock.fprintAuth = lib.mkForce false;

  # Distinguish it from the real machine on the LAN and in tailscale.
  networking.hostName = lib.mkForce "t14-test";
}
