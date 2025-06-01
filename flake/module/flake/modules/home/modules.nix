{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;

  inherit (config.lupinix.home) modules;
in {
  options.lupinix.home.modules = mkOption {
    type = types.attrsOf types.deferredModule;
    default = {};
  };

  config.flake.homeModules = modules;
}
