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
    filterAttrs
    foldl'
    hasAttrByPath
    hasAttr
    mapAttrs'
    mapAttrs
    mkIf
    mkOption
    nameValuePair
    types
    ;

  mkModuleOption = mkOption {
    type = types.attrsOf types.deferredModule;
    default = { };
  };

  mkConfigOption = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          system = mkOption {
            type = types.str;
          };
          modules = mkModuleOption;
          configuration = mkOption {
            type = types.unspecified;
          };
        };
      }
    );
    default = { };
  };

  coreOptions = {
    modules = {
      nixos = mkModuleOption;
      home = mkModuleOption;
      hjem = mkModuleOption;
    };
    configurations = {
      nixos = mkConfigOption;
      home = mkConfigOption;
      hjem = mkConfigOption;
    };
  };

  processClusterConfigs =
    {
      type,
      clusters,
    }:
    foldl'
      (
        acc: cluster:
        let
          clusterName = cluster.name;
          clusterConfig = cluster.value;
          clusterModules = clusterConfig.modules.${type};
          clusterConfigs = clusterConfig.configurations.${type};
        in
        acc
        // (mapAttrs' (
          name: config:
          nameValuePair "${clusterName}-${name}" (config // { modules = attrValues clusterModules; })
        ) clusterConfigs)
      )
      { }
      (
        lib.attrsToList (
          filterAttrs (_name: config: hasAttrByPath [ "configurations" type ] config) clusters
        )
      );
in
{
  options.lupinix = coreOptions // {
    clusters = mkOption {
      type = types.attrsOf (types.submodule { options = coreOptions; });
      default = { };
      description = "Cluster configurations";
    };
  };

  config.flake =
    let
      inherit (config.lupinix)
        clusters
        modules
        configurations
        ;
    in
    rec {
      nixosModules = modules.nixos;
      homeModules = modules.home;
      hjemModules = modules.hjem;

      nixosConfigurations = mkIf (hasAttr "nixpkgs" inputs) (
        mapAttrs
          (
            hostName: hostConfig:
            withSystem hostConfig.system (
              {
                inputs',
                self',
                pkgs,
                system,
                ...
              }:
              inputs.nixpkgs.lib.nixosSystem {
                inherit pkgs system;
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
                    { networking.hostName = hostName; }
                    hostConfig.configuration
                  ]
                  ++ hostConfig.modules
                  ++ (attrValues nixosModules);
              }
            )
          )
          (
            configurations.nixos
            // processClusterConfigs {
              type = "nixos";
              inherit clusters;
            }
          )
      );

      homeConfigurations = mkIf (hasAttr "home-manager" inputs) (
        mapAttrs
          (
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
                modules =
                  [
                    { home.username = userName; }
                    userConfig.configuration
                  ]
                  ++ userConfig.modules
                  ++ (attrValues homeModules);
              }
            )
          )
          (
            configurations.home
            // processClusterConfigs {
              type = "home";
              inherit clusters;
            }
          )
      );
    };
}
