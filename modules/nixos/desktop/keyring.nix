# gnome-keyring as the Secret Service — mirrors ente-auth.yml, which installed
# it for Ente Auth. The module also adds its PAM hook to login and puts the
# D-Bus service in place, so libsecret clients can start it on demand.
{ ... }:
{
  services.gnome.gnome-keyring.enable = true;
}
