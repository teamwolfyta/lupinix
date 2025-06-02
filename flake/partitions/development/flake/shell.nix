{
  mkShell,
  pkgs,
  ...
}:
mkShell {
  nativeBuildInputs = with pkgs; [
    deadnix
    editorconfig-checker
    lefthook
    mdformat
    nil
    nixfmt-rfc-style
    statix
    taplo
    treefmt
  ];

  shellHook = ''
    lefthook install
  '';
}
