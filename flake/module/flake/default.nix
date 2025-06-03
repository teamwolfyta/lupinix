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

  mkModuleOption = mkOption {
    type = types.attrsOf types.deferredModule;
    default = { };
  };

  mkTypeOption = {
    modules = mkModuleOption;
    configurations = mkConfigOption;
  };

  coreOptions = {
    nixos = mkTypeOption;
    home = mkTypeOption;
  };

  processClusterConfigs =
    {
      basePath,
      configurations,
      clusters,
    }:
    foldl'
      (
        acc: cluster:
        let
          clusterName = cluster.name;
          clusterConfig = cluster.value;
          clusterModules = clusterConfig.${basePath}.modules;
          clusterConfigs = clusterConfig.${basePath}.configurations;
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
          filterAttrs (_name: config: hasAttrByPath [ basePath "configurations" ] config) clusters
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
        nixos
        home
        ;
    in
    rec {
      nixosModules = nixos.modules;
      homeModules = home.modules;

      nixosConfigurations = mkIf (hasAttr "nixpkgs" inputs) (
        mapAttrs
          (
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
                    { networking.hostName = hostName; }
                    hostConfig.configuration
                  ]
                  ++ hostConfig.modules
                  ++ (attrValues nixosModules);
              }
            )
          )
          (
            nixos.configurations
            // processClusterConfigs {
              inherit clusters;
              inherit (nixos) configurations;
              basePath = "nixos";
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
            home.configurations
            // processClusterConfigs {
              inherit clusters;
              inherit (home) configurations;
              basePath = "home";
            }
          )
      );
    };
}
