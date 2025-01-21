{ lib, config, apks, ... }:
with lib;
let
  cfg = config.apps.kvaesitso;
in
{
  options.apps.kvaesitso = {
    enable = mkEnableOption "Kvaesitso Launcher";
  };

  config = mkIf cfg.enable {
    environment.apps = with apks; [
      kvaesitso
    ];
  };
}
