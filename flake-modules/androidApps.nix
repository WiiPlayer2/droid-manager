{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    mkOptionType
    isFunction
    mergeOneOption
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
  functionType = mkOptionType {
    name = "function";
    check = isFunction;
    merge = mergeOneOption;
  };
in
mkTransposedPerSystemModule {
  name = "androidApps";
  option = mkOption {
    type = with types; lazyAttrsOf (oneOf [ pathInStore functionType ]);
    default = { };
    description = ''
      An attribute set of Android apps
    '';
  };
  file = ./androidApps.nix;
}
