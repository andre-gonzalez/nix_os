# something-x — GTK4 device manager for Nothing earbuds. Not in nixpkgs; Arch
# used the AUR package, which builds the PyPI sdist exactly like this
# (including dropping the setuptools-scm requirement, since an sdist carries
# its version already).
{ lib, python3Packages, fetchPypi, gobject-introspection, wrapGAppsHook4
, gtk4, libadwaita, pulseaudio }:
python3Packages.buildPythonApplication rec {
  pname = "something-x";
  version = "1.9.4";
  pyproject = true;

  src = fetchPypi {
    pname = "something_x";
    inherit version;
    hash = "sha256-ZJ4KHz3CldYdXrCpp1TJhVIzpWTbM4v2ycWMt8psz8Y=";
  };

  postPatch = ''
    sed -i 's/, "setuptools-scm>=8"//' pyproject.toml
  '';

  build-system = with python3Packages; [ setuptools wheel ];
  nativeBuildInputs = [ gobject-introspection wrapGAppsHook4 ];
  buildInputs = [ gtk4 libadwaita ];
  dependencies = with python3Packages; [ pygobject3 pycairo dbus-python ];

  # One wrapper, not two: let the Python wrapper carry the GApps environment.
  dontWrapGApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}" --prefix PATH : ${lib.makeBinPath [ pulseaudio ]})
  '';

  meta = {
    description = "GTK4 device manager for Nothing earbuds on Linux";
    homepage = "https://pypi.org/project/something-x/";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "something-x";
  };
}
