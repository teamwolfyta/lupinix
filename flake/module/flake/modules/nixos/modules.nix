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
  options.lupinix.nixos.modules = mkOption {
    type = types.attrsOf types.deferredModule;
    default = {};
  };

  config.flake.nixosModules = config.lupinix.nixos.modules;
}
