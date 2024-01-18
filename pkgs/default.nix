{ pkgs, ... }:

{
  calamares-nixos-extensions-provision = pkgs.callPackage ./calamares-nixos-extensions-provision { };
  calamares-nixos-extensions-install = pkgs.callPackage ./calamares-nixos-extensions-install { };
}
