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

  inherit (config.lupinix.nixos) modules;
in {
  options.lupinix.nixos.modules = mkOption {
    type = types.attrsOf types.deferredModule;
    default = {};
  };

  config.flake.nixosModules = modules;
}
