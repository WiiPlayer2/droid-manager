{
  description = "Android Manager based on Nix";

  # nixConfig = {
  #   trusted-substituters = [
  #     "https://nix-on-droid.cachix.org"
  #   ];
  #   trusted-public-keys = [
  #     "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
  #   ];
  # };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-bundle = {
      url = "github:nix-community/nix-bundle";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      # inputs.nixpkgs.follows = "nixpkgs";
      # inputs.nixpkgs-for-bootstrap.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./bundlers
        ./flake-modules
        ./pkgs

        ./lib.nix
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
        packages.default = pkgs.hello;
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
        droidManagerConfigurations.example = self.lib.droidManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          modules = [
            (
              { pkgs, ... }:
              {
                build.activation.default.printenv = ''
                  printenv
                '';
              }
            )
          ];
        };
      };
    };
}
