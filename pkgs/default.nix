{
  perSystem =
    { pkgs, ... }:
    {
      packages.droid-manager = pkgs.callPackage ./droid-manager {};
    };
}
