{
  config,
  inputs,
  lib,
  self,
  withSystem,
  ...
}: let
  inherit
    (lib)
    attrValues
    hasAttr
    mapAttrs
    mkIf
    mkOption
    types
    ;

  inherit (config.lupinix.nixos) modules;
in {
  options.lupinix.nixos = {
    configurations = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            system = mkOption {
              type = types.str;
            };
            configuration = mkOption {
              type = types.unspecified;
            };
          };
        }
      );
      default = {};
    };
    modules = mkOption {
      type = types.attrsOf types.deferredModule;
      default = {};
    };
  };

  config.flake = {
    nixosConfigurations = mkIf (hasAttr "nixpkgs" inputs) (
      mapAttrs (
        hostName: hostConfig:
          withSystem hostConfig.system (
            {
              inputs',
              self',
              system,
              ...
            }:
              inputs.nixpkgs.lib.nixosSystem {
                inherit system;
                specialArgs = {
                  inherit
                    system
                    inputs
                    self
                    inputs'
                    self'
                    ;
                };
                modules =
                  [
                    {
                      networking.hostName = hostName;
                    }
                    hostConfig.configuration
                  ]
                  ++ (attrValues modules);
              }
          )
      )
      config.lupinix.nixos.configurations
    );

    nixosModules = modules;
  };
}
