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
            inherit (pkgs) fetchurl system;
            callPackage = callPackageWith final;
            fetchFromFDroid =
              { name
              , revision
              , repo ? "https://f-droid.org/repo/"
              , hash ? ""
              }:
              let
                fixedRepo = removeSuffix "/" repo;
                fullUrl = "${repo}/${name}_${revision}.apk";
              in
              pkgs.fetchurl {
                url = fullUrl;
                inherit hash;
              };
          };
          appsFix = fix appsBase;
          appsByName = packagesFromDirectoryRecursive {
            inherit (appsFix) callPackage;
            directory = ./by-name;
          };
          apps = appsFix // appsByName;
        in
          apps;
    };
}
