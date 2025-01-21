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
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";

      # The main branch follows the "canary" channel of the Android SDK
      # repository. Use another android-nixpkgs branch to explicitly
      # track an SDK release channel.
      #
      # url = "github:tadfisher/android-nixpkgs/stable";
      # url = "github:tadfisher/android-nixpkgs/beta";
      # url = "github:tadfisher/android-nixpkgs/preview";
      # url = "github:tadfisher/android-nixpkgs/canary";

      # If you have nixpkgs as an input, this will replace the "nixpkgs" input
      # for the "android" flake.
      #
      inputs.nixpkgs.follows = "nixpkgs";
    };
    make-wrapper = {
      url = "github:polygon/make-wrapper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.pkgs-by-name-for-flake-parts.flakeModule

        ./apks
        ./bundlers
        ./flake-modules
        ./pkgs

        ./lib.nix
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        pkgsDirectory = ./pkgs;
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
        droidManagerConfigurations.example = self.lib.droidManagerConfiguration {
          deviceSystem = "aarch64-linux";
          modules = [
            (
              { pkgs, apks, ... }:
              {
                environment.apps = with apks; [
                  f-droid
                ];
              }
            )
          ];
        };
      };
    };
}
