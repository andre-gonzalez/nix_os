# Databricks CLI — the official static release binary, pinned to what Arch
# runs (AUR databricks-cli-bin 1.19.0). nixpkgs' databricks-cli is 1.7.0, a
# year behind the version the Databricks tooling here is used with.
{ stdenvNoCC, lib, fetchzip }:
stdenvNoCC.mkDerivation rec {
  pname = "databricks-cli";
  version = "1.19.0";

  src = fetchzip {
    url = "https://github.com/databricks/cli/releases/download/v${version}/databricks_cli_${version}_linux_amd64.tar.gz";
    hash = "sha256-ZUH1Q3PEXRg83Lt0RABEFRm92Rp7UKR01Vh2z1sOnkQ=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall
    install -Dm755 databricks $out/bin/databricks
    runHook postInstall
  '';

  meta = {
    description = "Databricks CLI";
    homepage = "https://github.com/databricks/cli";
    license = lib.licenses.unfree; # Databricks License
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "databricks";
  };
}
