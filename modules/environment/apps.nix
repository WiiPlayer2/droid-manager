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
      install-apks =
        let
          apksPaths = concatStringsSep " " cfg;
          adb = "${pkgs.android-tools}/bin/adb";
          installCommand = "${adb} install-multi-package -d ${apksPaths}";
        in
          installCommand;
    };
  };
}
