_: {
  systems = ["x86_64-linux"];

  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells = {
      default = config.devShells.development;
      development = pkgs.callPackage ./shell.nix {};
    };
  };
}
