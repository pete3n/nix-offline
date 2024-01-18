{
  description = "Custom NixOS 23.11 installation media - offline patch";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs";
  };

  
  outputs = { self, nixpkgs, ... }@inputs: rec {

    nixosConfigurations = {
      offline-provisioner = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [
          ({ pkgs, lib, ... }: {
            nixpkgs.overlays = [
              (self: super: {
                calamares-nixos-extensions = super.callPackage ./pkgs/calamares-nixos-extensions-offline-provision { };
              })
            ];
          })
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
          ({ pkgs, config, ... }: {
            isoImage = {
             # storeContents = [ 
             #   config.system.build.toplevel
             # ];
              squashfsCompression = "gzip -Xcompression-level 1";
            };
          })
        ];
      };

      offline-installer = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
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
          ({ pkgs, config, ... }: {
            isoImage = {
              storeContents = [ 
                config.system.build.toplevel
              ];
              includeSystemBuildDependencies = true;
              squashfsCompression = "gzip -Xcompression-level 1";
            };
          })
        ];
      };
    };

    iso.offline-provisioner = nixosConfigurations.offline-provisioner.config.system.build.isoImage;
    iso.offline-installer = nixosConfigurations.offline-installer.config.system.build.isoImage;
  };
}
