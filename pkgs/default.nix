{ pkgs, ... }:

{
  calamares-nixos-extensions-offline-provision = pkgs.callPackage ./calamares-nixos-extensions-offline-provision { };
  calamares-nixos-extensions-offline-install = pkgs.callPackage ./calamares-nixos-extensions-offline-install { };
}
