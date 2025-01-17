{ inputs, ... }:
{
  perSystem =
    { pkgs, inputs', system, ... }:
    {
      bundlers.androidShell = import ./android-shell.nix {
        inherit system;
        inherit (inputs) self nix-on-droid nixpkgs nix-bundle;
        # nix-bundle = import inputs.nix-bundle { nixpkgs = pkgs; };
      };
    };
}
