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
  name = "androidApps";
  option = mkOption {
    type = with types; lazyAttrsOf package;
    default = { };
    description = ''
      An attribute set of Android apps
    '';
  };
  file = ./androidApps.nix;
}
