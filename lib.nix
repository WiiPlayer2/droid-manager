{ lib, ... }:
{
  flake.lib.droidManagerConfiguration =
    { pkgs
    , modules
    }:
    let
      inherit (lib)
        evalModules;

      evaluatedModules = evalModules {
        modules = [
          ./modules
        ] ++ modules;
        specialArgs = {
          inherit pkgs;
        };
      };
      activationPackage = evaluatedModules.config.build.activationPackage;
    in
      activationPackage;
}
