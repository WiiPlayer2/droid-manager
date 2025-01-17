{
  perSystem =
    { pkgs, ... }:
    {
      androidApps = {
        f-droid = pkgs.callPackage ./by-name/f-droid.nix {};
      };
    };
}
