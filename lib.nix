{ lib, ... }:
{
  flake.lib.droidManagerConfiguration =
    { modules }:
    let
      inherit (lib)
        evalModules;

      evaluatedModules = evalModules {
        modules = [
          ./modules
        ] ++ modules;
      };
      activationPackage = evaluatedModules;
    in
      activationPackage;
}
