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
in {
  options.lupinix.nixos.configurations = mkOption {
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

  config.flake.nixosConfigurations = mkIf (hasAttr "nixpkgs" inputs) (
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
                ++ (attrValues config.lupinix.nixos.modules);
            }
        )
    )
    config.lupinix.nixos.configurations
  );
}
