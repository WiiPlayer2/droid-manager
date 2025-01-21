{ lib, inputs, ... }:
{
  flake.lib.droidManagerConfiguration =
    { deviceSystem
    , hostSystem ? "x86_64-linux" # Assuming x64 by default due to it being the most probably answer and also most likely to work compiling on
    , modules
    , isRooted ? false
    }:
    let
      inherit (lib)
        evalModules;

      configured-nixpkgs = system: import inputs.nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            # android-sdk = inputs.android-nixpkgs.${prev.system}.
            make-wrapper = inputs.make-wrapper.packages.${prev.system}.make-wrapper;
          })
        ];
        config = {
          android_sdk.accept_license = true;
        };
      };

      evaluatedModules = evalModules {
        modules = [
          ./modules
          {
            build.activation.enableRoot = isRooted;
          }
        ] ++ modules;
        specialArgs = {
          inherit inputs;
          pkgs = configured-nixpkgs deviceSystem;
          hostPkgs = configured-nixpkgs hostSystem;
          apks = inputs.self.androidApps.${deviceSystem};
        };
      };
      activationPackage = evaluatedModules.config.build.activationPackage;
    in
      activationPackage;
}
