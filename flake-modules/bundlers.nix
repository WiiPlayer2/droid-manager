{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "bundlers";
  option = mkOption {
    type = with types; lazyAttrsOf (functionTo package);
    default = { };
    description = ''
      An attribute set of bundlers that can be used with `nix bundle`
    '';
  };
  file = ./bundlers.nix;
}
