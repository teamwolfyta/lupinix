{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = import ./flake/module-list.nix;
      systems = [];
    };
}
