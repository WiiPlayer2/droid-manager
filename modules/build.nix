{ lib, config, pkgs, inputs, ... }:
let
  inherit (lib)
    mkOption
    types
    concatStringsSep
    attrsToList
    map
    filter
    makeBinPath
    warn;

  mkActivationOption = description: mkOption {
    inherit description;
    type = with types; attrsOf (submodule {
      options = {
        script = mkOption {
          type = str;
        };
        needsRoot = mkOption {
          type = bool;
          default = false;
        };
      };
    });
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
        pkgs.writeScript name value.script;
      mkActivationScriptInvocation =
        { name, value } @ script:
        let
          displayName =
            if value.needsRoot
            then warn "Activation \"${name}\" on ${target} needs root to execute." "${name} (using root)"
            else name;
        in
        ''
          noteEcho "[Activating ${displayName} on ${target}]"
          ${mkActivationScript script}
        '';
      canExecute =
        { name, value }:
        !value.needsRoot || config.build.activation.enableRoot;
      mkActivationBlock =
        block:
        concatStringsSep
        "\n"
        (
          map
          mkActivationScriptInvocation
          (
            filter
            canExecute
            (attrsToList block)
          )
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
      enableRoot = mkOption {
        type = types.bool;
        default = false;
      };
    };

    activationPackage = mkOption {
      description = "Activation package";
      type = types.package;
      readOnly = true;
      internal = true;
    };
  };

  config.build = {
    activation.host.default.activate-device.script =
      let
        deviceActivationScript = mkTargetActivationScript "device" config.build.activation.device;
        deviceActivationPackage = 
          let
            name = "device-activation-script";
            availableScripts = with pkgs; [
              (writeShellScriptBin "from-store" "echo \"/tmp/dat$1\"")
            ];
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
            ${pkgs.make-wrapper}/bin/wrapProgram $out/bin/activate \
              --prefix PATH : ${makeBinPath availableScripts}
          '';
        bundledActivationScript = inputs.self.bundlers.${pkgs.system}.androidShell deviceActivationPackage;
        script =
          let
            adb = "${pkgs.android-tools}/bin/adb";
          in
          ''
            # TODO: verbose and dry-run
            set -e
            ${adb} push ${bundledActivationScript} /tmp/activate
            trap "${adb} shell rm -r /tmp/activate /tmp/dat /tmp/run /tmp/env /tmp/.cache" EXIT
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
