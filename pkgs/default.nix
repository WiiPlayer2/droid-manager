{
  perSystem =
    { pkgs, ... }:
    {
      packages.droid-manager = pkgs.callPackage ./droid-manager {};
      packages.talloc-static = pkgs.callPackage ./talloc-static.nix {};
    };
}
