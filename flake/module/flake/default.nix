{
  config,
  inputs,
  lib,
  self,
  withSystem,
  ...
}:
let
  inherit (lib)
    attrValues
    hasAttr
    mapAttrs
    mkIf
    mkOption
    types
    ;

  mkConfigOption = mkOption {
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
    default = { };
  };

  mkModuleOption = mkOption {
    type = types.attrsOf types.deferredModule;
    default = { };
  };

  mkTypeOption = {
    modules = mkModuleOption;
    configurations = mkConfigOption;
  };
in
{
  options.lupinix = {
    nixos = mkTypeOption;
    home = mkTypeOption;
  };

  config.flake =
    let
      inherit (config.lupinix)
        nixos
        home
        ;
    in
    rec {
      nixosModules = nixos.modules;
      homeModules = home.modules;

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
              modules = [
                { networking.hostName = hostName; }
                hostConfig.configuration
              ] ++ (attrValues nixosModules);
            }
          )
        ) nixos.configurations
      );

      homeConfigurations = mkIf (hasAttr "home-manager" inputs) (
        mapAttrs (
          userName: userConfig:
          withSystem userConfig.system (
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
              modules = [
                { home.username = userName; }
                userConfig.configuration
              ] ++ (attrValues homeModules);
            }
          )
        ) home.configurations
      );
    };
}
