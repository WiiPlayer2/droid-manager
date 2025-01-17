{ lib, inputs, ... }:
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
          inherit pkgs inputs;
          apks = inputs.self.androidApps.${pkgs.system};
        };
      };
      activationPackage = evaluatedModules.config.build.activationPackage;
    in
      activationPackage;
}
