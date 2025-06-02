{ config, ... }:
{
  flake = {
    flakeModule = config.flake.flakeModules.default;
    flakeModules = {
      default = config.flake.flakeModules.lupinix;
      lupinix = import ./flake;
    };
  };
}
