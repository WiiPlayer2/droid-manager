{ lib, config, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    concatStringsSep
    attrsToList;

  mkActivationOption = description: mkOption {
    inherit description;
    type = with types; attrsOf str;
    default = {};
  };

  activationScript =
    let
      mkActivationScript =
        { name, value }:
        pkgs.writeScript name value;
      mkActivationScriptInvocation =
        { name, value } @ script:
        ''
          noteEcho "[Activating ${name}]"
          ${mkActivationScript script}
        '';
      mkActivationBlock =
        block:
        concatStringsSep
        "\n"
        (
          map
          mkActivationScriptInvocation
          (attrsToList block)
        );

      cfg = config.build.activation;
    in
    pkgs.writeScript "activation-script" ''
      ${builtins.readFile ./lib-bash/color-echo.sh}
      ${builtins.readFile ./lib-bash/activation-init.sh}
      
      ${mkActivationBlock cfg.early}
      ${mkActivationBlock cfg.default}
      ${mkActivationBlock cfg.late}
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
