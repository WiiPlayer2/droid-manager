{ inputs, ... }:
{
  perSystem =
    { pkgs, inputs', ... }:
    {
      bundlers.androidShell = import ./android-shell.nix {
        inherit pkgs;
        inherit (inputs) self nix-on-droid nixpkgs;
        nix-bundle = import inputs.nix-bundle { nixpkgs = pkgs; };
      };
    };
}
