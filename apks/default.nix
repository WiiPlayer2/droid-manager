{ inputs, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      androidApps =
        let
          inherit (lib)
            fix
            extends
            callPackageWith
            removeSuffix
            packagesFromDirectoryRecursive;

          appsBase = final: {
            hostPkgs.x86_64-linux = (import inputs.nixpkgs {
              system = "x86_64-linux";
              config = {
                android_sdk.accept_license = true;
                allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
                  "android-sdk-cmdline-tools"
                  "android-sdk-tools"
                ];
              };
            });
          };
          appsFix = fix appsBase;
          appsByName = packagesFromDirectoryRecursive {
            callPackage = callPackageWith (pkgs // appsFix // appsByName);
            directory = ./by-name;
          };
          apps = appsFix // appsByName;
        in
          apps;
    };
}
