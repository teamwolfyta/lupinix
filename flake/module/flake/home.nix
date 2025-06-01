{
  config,
  inputs,
  lib,
  self,
  withSystem,
  ...
}: let
  inherit (lib) types;
  inherit (lib.attrsets) attrValues hasAttr mapAttrs;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;

  inherit (config.lupinix.home) modules;
in {
  options.lupinix.home = {
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
    homeConfigurations = mkIf (hasAttr "home-manager" inputs) (
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
                ++ (attrValues modules);
            }
        ))
      )
      config.lupinix.home.configurations
    );

    homeModules = modules;
  };
}
