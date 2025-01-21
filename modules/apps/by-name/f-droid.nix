{ lib, config, apks, ... }:
with lib;
let
  cfg = config.apps.f-droid;
in
{
  options.apps.f-droid = {
    enable = mkEnableOption "F-Droid app store";
  };

  config = mkIf cfg.enable {
    environment.apps = with apks; [
      f-droid
    ];
  };
}
