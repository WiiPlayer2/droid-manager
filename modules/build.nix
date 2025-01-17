{ lib, config, pkgs, inputs, ... }:
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

  mkTargetActivationOption = description: {
    early = mkActivationOption "Early activation scripts (${description})";
    default = mkActivationOption "Activation scripts (${description})";
    late = mkActivationOption "Late activation scripts (${description})";
  };

  mkTargetActivationScript =
    target: cfg:
    let
      mkActivationScript =
        { name, value }:
        pkgs.writeScript name value;
      mkActivationScriptInvocation =
        { name, value } @ script:
        ''
          noteEcho "[Activating ${name} on ${target}]"
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
    in
    pkgs.writeScript "${target}-activation-script" ''
      ${builtins.readFile ./lib-bash/color-echo.sh}
      ${builtins.readFile ./lib-bash/activation-init.sh}
      
      ${mkActivationBlock cfg.early}
      ${mkActivationBlock cfg.default}
      ${mkActivationBlock cfg.late}
    '';

  activationScript = mkTargetActivationScript "host" config.build.activation.host;
in
{
  options.build = {
    activation = {
      device = mkTargetActivationOption "device";
      host = mkTargetActivationOption "host";
    };

    activationPackage = mkOption {
      description = "Activation package";
      type = types.package;
      readOnly = true;
      internal = true;
    };
  };

  config.build = {
    activation.host.default.activate-device =
      let
        deviceActivationScript = mkTargetActivationScript "device" config.build.activation.device;
        bundledActivationScript = inputs.self.bundlers.${pkgs.system}.androidShell (
          let
            name = "device-activation-script";
          in
          pkgs.runCommandLocal
          name
          {
            pname = name;
            meta.mainProgram = "activate";
          }
          ''
            mkdir --parents $out/bin
            ln -s ${deviceActivationScript} $out/bin/activate
          ''
        );
        script =
          let
            adb = "${pkgs.android-tools}/bin/adb";
          in
          ''
            # TODO: verbose and dry-run
            set -e
            ${adb} push ${bundledActivationScript} /tmp/activate
            trap "${adb} shell rm -r /tmp/activate /tmp/dat /tmp/run /tmp/env" EXIT
            ${adb} shell /tmp/activate
          '';
      in
        script;

    activationPackage =
      let
        name = "droid-manager-activate";
      in
      pkgs.runCommandLocal
      name
      {
        pname = name;
        meta.mainProgram = "activate";
      }
      ''
        mkdir --parents $out/bin
        ln -s ${activationScript} $out/bin/activate
      '';
  };
}
