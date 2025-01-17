{ lib, config, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types;

  mkActivationOption = description: mkOption {
    inherit description;
    type = with types; attrsOf str;
    default = {};
  };

  activationScript = pkgs.writeScript "activation-script" ''
    echo hi
  '';
in
{
  options.build = {
    activation = {
      early = mkActivationOption "Early activation scripts";
      default = mkActivationOption "Activation scripts";
      late = mkActivationOption "Late activation scripts";
    };

    activationPackage = mkOption {
      description = "Activation package";
      type = types.package;
      readOnly = true;
      internal = true;
    };
  };

  config.build = {
    activationPackage =
      pkgs.runCommand
      "droid-manager-generation"
      {
        pname = "droid-manager-generation";
        preferLocalBuild = true;
        allowSubstitutes = false;
        meta.mainProgram = "activate";
      }
      ''
        mkdir --parents $out/bin

        cp ${activationScript} $out/bin/activate
      '';
  };
}
