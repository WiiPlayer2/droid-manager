{ inputs, ... }:
{
  perSystem =
    { pkgs, inputs', system, self', ... }:
    {
      bundlers.androidShell = import ./android-shell.nix {
        inherit system self';
        inherit (inputs) self nix-on-droid nixpkgs nix-bundle;
        # nix-bundle = import inputs.nix-bundle { nixpkgs = pkgs; };
      };
    };
}
