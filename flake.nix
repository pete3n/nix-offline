{
  description = "Custom NixOS 23.11 installation media - offline patch";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs: 
  rec {
    nixosConfigurations.getac-iso = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ({ pkgs, lib, ... }: {
          nixpkgs.overlays = [
            (self: super: {
              calamares-nixos-extensions = super.calamares-nixos-extensions.overrideAttrs (oldAttrs: rec {
                patches = oldAttrs.patches or [] ++ [ ./patches/welcome.patch ];
              });
            })
          ];
        })
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
        ({ pkgs, ... }: {
          isoImage.squashfsCompression = "gzip -Xcompression-level 1";
          environment.systemPackages = with pkgs; [ git pkgs.neovim ];
        })
      ];
    };
    iso.getac = nixosConfigurations.getac-iso.config.system.build.isoImage;
  };
}
