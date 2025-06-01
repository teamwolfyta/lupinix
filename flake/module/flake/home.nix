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

  conf_configurations = config.lupinix.home.configurations or {};
  conf_modules = config.lupinix.home.modules or {};
in {
  options.lupinix.home = {
    configurations = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = {};
    };
    modules = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = {};
    };
  };

  config.flake = {
    homeConfigurations = mkIf (hasAttr "home-manager" inputs) (mapAttrs (
        userName: userConfig: (withSystem userConfig.nixpkgs.hostPlatform ({
          pkgs,
          self',
          inputs',
          system,
          ...
        }:
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            specialArgs = {inherit system inputs self inputs' self';};
            modules =
              [
                {
                  home.username = userName;
                }
                userConfig
              ]
              ++ (attrValues conf_modules);
          }))
      )
      conf_configurations);
    homeModules = conf_modules;
  };
}
