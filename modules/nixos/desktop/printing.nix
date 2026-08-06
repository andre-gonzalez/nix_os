# CUPS printing + a virtual "print to PDF" queue.
#
# Both workstation profiles (workstation, samsung-expert) get this via
# modules/nixos/desktop/default.nix.
{ pkgs, ... }:
{
  services.printing = {
    enable = true;

    # Free drivers only. gutenprint covers most Canon/Epson/Brother/HP models;
    # add hplip (HP, non-free plugin for some lasers) or brlaser (Brother mono
    # lasers) here if a specific printer needs it.
    drivers = with pkgs; [
      gutenprint
      gutenprintBin
    ];

    # CUPS listens on localhost only (the NixOS default); nothing is exposed to
    # the LAN, so no firewall holes are needed for cupsd itself.
    browsing = false;
    webInterface = true;
  };

  # Virtual PDF printer: jobs sent to the "cups-pdf" queue land as PDFs in the
  # spool dir below instead of on paper. The upstream module installs the queue
  # and the cups-pdf backend for us.
  services.printing.cups-pdf = {
    enable = true;
    instances.cups-pdf.settings = {
      # ~/PDF (per-user, ${HOME} is expanded by cups-pdf) rather than the
      # default /var/spool/cups-pdf-<user>, so output is where we can reach it.
      Out = "\${HOME}/PDF";
      UserUMask = "0022";
    };
  };

  # Driverless network printers (IPP Everywhere / AirPrint) are discovered over
  # mDNS. avahi's openFirewall punches the single UDP 5353 hole this needs; the
  # rest of the default-deny policy in base/firewall.nix stays intact.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # CLI/GUI queue management. Administration goes through the wheel group, which
  # frank is already in (see base/users.nix).
  environment.systemPackages = with pkgs; [
    cups
    system-config-printer
  ];
}
