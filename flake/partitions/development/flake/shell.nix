{
  mkShell,
  pkgs,
  ...
}:
mkShell {
  nativeBuildInputs = with pkgs; [
    alejandra
    deadnix
    editorconfig-checker
    lefthook
    mdformat
    nil
    statix
    taplo
    treefmt
  ];

  shellHook = ''
    lefthook install
  '';
}
