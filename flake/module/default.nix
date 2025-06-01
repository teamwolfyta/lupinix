{config, ...}: {
  flake = {
    flakeModule = config.flakeModules.default;
    flakeModules = {
      default = config.flakeModules.lupinix;
      lupinix = import ./flake;
    };
  };
}
