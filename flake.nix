{
  description = "Custom NixOS offline installation ISO";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs";

    nixos-flake = {
      url = "path:./nix-cfg";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-flake, ... }@inputs: rec {

    systems = [
      "x86_64-linux"
      "aarch64-linux" 
    ];

    nixosConfigurationsForAllSystems = system: {
      "offline-provisioner-${system}" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        inherit system;
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
              squashfsCompression = "gzip -Xcompression-level 1";
            };
          })
        ];
      };

      "offline-installer-${system}" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        inherit system;
        modules = [
          ./nix-cfg/nixos/configuration.nix
          ({ pkgs, lib, ... }: {
            nixpkgs.overlays = [
              (self: super: {
                calamares-nixos-extensions = super.callPackage ./pkgs/calamares-nixos-extensions-offline-install { };
              })
            ];
          })
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
          ({ pkgs, config, ... }: {
            isoImage = {
              contents = [
                {
                    source = ./nixos;
                    target = "/nixos";
                }
              ];
              storeContents = [ 
                config.system.build.toplevel
              ];
              includeSystemBuildDependencies = true;
              squashfsCompression = "gzip -Xcompression-level 1";
            };
          })
        ];
      };

      "offline-${system}" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        inherit system;
        modules = [
          ./nix-cfg/nixos/configuration.nix
          ({ pkgs, lib, ... }: {
            nixpkgs.overlays = [
              (self: super: {
                calamares-nixos-extensions = super.callPackage ./pkgs/calamares-nixos-extensions-offline { };
              })
            ];
          })
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
          ({ pkgs, config, ... }: {
            isoImage = {
              contents = [
                {
                    source = ./nix-cfg;
                    target = "/nix-cfg";
                }
              ];
              storeContents = [ 
                config.system.build.toplevel
              ];
              #includeSystemBuildDependencies = true;
              squashfsCompression = "gzip -Xcompression-level 1";
            };
          })
        ];
      };

      "offline-flake-${system}" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ({ pkgs, lib, ... }: {
            nixpkgs.overlays = [
              (self: super: {
                calamares-nixos-extensions = super.callPackage ./pkgs/calamares-nixos-extensions-offline { };
              })
            ];
          })
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
          ({ pkgs, config, ... }: {
            isoImage = {
              contents = [
                {
                    source = ./nix-cfg;
                    target = "/nix-cfg";
                }
              ];
              storeContents = [ 
                config.system.build.toplevel
                nixos-flake.nixosConfigurations.nix-tac.config.system.build.toplevel
              ];
              #includeSystemBuildDependencies = true;
              squashfsCompression = "gzip -Xcompression-level 1";
            };
          })
        ];
      };
    };
   
    # Generate nixosConfigurations for each system
    nixosConfigurations = builtins.foldl' (acc: system: acc // (nixosConfigurationsForAllSystems system)) { } systems;

    # Generate iso configurations for each system
    iso = builtins.mapAttrs (name: config: config.config.system.build.isoImage) nixosConfigurations;
  };
}
