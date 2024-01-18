{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "calamares-nixos-extensions-offline";
  version = "provision-v0.1.1";

  src = fetchFromGitHub {
    owner = "pete3n";
    repo = "calamares-nixos-extensions-offline";
    rev = version;
    hash = "sha256-lwFgi2/Jr7k/nBR/6AdcIDNR3pfS3O8rQbvm9BBzR8I=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{lib,share}/calamares
    cp -r modules $out/lib/calamares/
    cp -r config/* $out/share/calamares/
    cp -r branding $out/share/calamares/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Calamares offline modules for NixOS";
    homepage = "https://github.com/NixOS/calamares-nixos-extensions-offline";
    license = with licenses; [ gpl3Plus bsd2 cc-by-40 cc-by-sa-40 cc0 ];
    maintainers = with maintainers; [ pete3n ];
    platforms = platforms.linux;
  };
}