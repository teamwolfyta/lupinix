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
  options.lupinix.home.configurations = mkOption {
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

  config.flake.homeConfigurations = mkIf (hasAttr "home-manager" inputs) (
    mapAttrs (
      userName: userConfig: (withSystem userConfig.system (
        {
          pkgs,
          self',
          inputs',
          system,
          ...
        }:
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
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
                  home.username = userName;
                }
                userConfig.configuration
              ]
              ++ (attrValues config.lupinix.home.modules);
          }
      ))
    )
    config.lupinix.home.configurations
  );
}
