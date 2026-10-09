# LibreOffice — libreoffice-still in roles/light_workstation/tasks/packages.yml.
# The xdg.mimeApps defaults for .docx/.xlsx/.pptx (home/default.nix) point at
# its writer/calc/impress desktop files, which did not exist without it.
{ pkgs, ... }:
{
  home.packages = [ pkgs.libreoffice-still ];
}
