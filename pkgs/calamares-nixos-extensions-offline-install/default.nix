{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation rec {
  pname = "calamares-nixos-extensions-offline";
  version = "install-v0.1.0";

  src = fetchFromGitHub {
    owner = "pete3n";
    repo = "calamares-nixos-extensions-offline";
    rev = version;
    hash = "sha256-KZHonKFeVQf0hX10VlyGkcIBh/RHuBZT89eJsoGiyBU=";
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
