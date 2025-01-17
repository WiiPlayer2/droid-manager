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
            removeSuffix;

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
          appsOverlay = final: prev: {
            callPackage = final.callPackage or (callPackageWith (prev // final));

            f-droid = prev.callPackage ./by-name/f-droid.nix {};
          };
          appsFix = fix (extends appsOverlay appsBase);
        in
          appsFix;
    };
}
