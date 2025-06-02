{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.partitions
  ];

  partitionedAttrs.devShells = "development";

  partitions."development" = {
    extraInputsFlake = ./development;
    module = ./development/flake;
  };
}
