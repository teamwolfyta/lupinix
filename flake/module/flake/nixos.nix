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

  conf_configurations = config.lupinix.nixos.configurations;
  conf_modules = config.lupinix.nixos.modules;
in {
  options.lupinix.nixos = {
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
    nixosConfigurations = mkIf (hasAttr "nixpkgs" inputs) (mapAttrs (
        hostName: hostConfig: (withSystem hostConfig.nixpkgs.hostPlatform ({
          inputs',
          self',
          system,
          ...
        }:
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {inherit system inputs self inputs' self';};
            modules =
              [
                {
                  networking = {
                    inherit hostName;
                  };
                }
                hostConfig
              ]
              ++ (attrValues conf_modules);
          }))
      )
      conf_configurations);
    nixosModules = conf_modules;
  };
}
