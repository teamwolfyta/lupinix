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
in {
  options.lupinix.home.modules = mkOption {
    type = types.attrsOf types.deferredModule;
    default = {};
  };

  config.flake.homeModules = config.lupinix.home.modules;
}
