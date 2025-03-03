{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.environment.apps;
in
{
  options.environment.apps = mkOption {
    description = "The Android apps to be installed on the device.";
    type = with types; listOf pathInStore;
    default = [];
  };

  config = {
    build.activation.host.early = mkIf (length cfg > 0) {
      install-apks.script =
        let
          apksPaths = concatStringsSep " " cfg;
          adb = "${pkgs.android-tools}/bin/adb";
          installCommand = "${adb} install-multi-package -d ${apksPaths}";
          pnames =
            concatStringsSep
            "\n"
            (
              sortOn
              (x: x)
              (
                map
                (x: x.meta.pname)
                cfg
              )
            );
          pnamesFile = pkgs.writeText "installed-apps" pnames;
          uninstallCommand = ''
            INSTALLED_APPS="$(${adb} shell cat /storage/self/primary/.droid-manager/installed_apks)"
            UNINSTALLABLE_APPS="$(${pkgs.coreutils}/bin/comm -3 <(echo "$INSTALLED_APPS") ${pnamesFile})"
            for apk in $UNINSTALLABLE_APPS; do
              # adb uninstall -k $apk
              adb shell cmd package uninstall -k $apk
            done
            adb push ${pnamesFile} /storage/self/primary/.droid-manager/installed_apks
          '';
          setupCommand = ''
            ${uninstallCommand}
            ${installCommand}
          '';
        in
          setupCommand;
    };
  };
}
