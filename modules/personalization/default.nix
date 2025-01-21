{ lib, config, apks, ... }:
with lib;
let
  cfg = config.personalization;
in
{
  options.personalization = {
    wallpaper = {
      home = mkOption {
        type = with types; nullOr pathInStore;
        default = null;
      };
      lock = mkOption {
        type = with types; nullOr pathInStore;
        default = null;
      };
    };
  };

  config = mkIf (cfg.wallpaper.home != null || cfg.wallpaper.lock != null) {
    environment.apps = with apks; [
      droid-manager-app
    ];

    build.activation.device.default.set-wallpaper =
      let
        mkIntentCall =
          { file
          , setHome ? true
          , setLock ? true
          }:
          ''
            am broadcast \
              -a com.example.droidmanagerapp.SET_WALLPAPER \
              -n com.example.droidmanagerapp/.SetWallpaper \
              --es WALLPAPER_FILE $(from-store "${file}") \
              --ez SET_HOME ${boolToString setHome} \
              --ez SET_LOCK ${boolToString setLock} \
              | ( ! grep 'result=-1' )
          '';
        intentCalls =
          if cfg.wallpaper.home == cfg.wallpaper.lock
          then [ (mkIntentCall { file = cfg.wallpaper.home; }) ]
          else
            map
            ({name, value}: mkIntentCall {
              file = value;
              setHome = name == "home";
              setLock = name == "lock";
            })
            (
              filter
              ({name, value}: value != null)
              (attrsToList cfg.wallpaper)
            );
        script =
          concatStringsSep
          "\n"
          intentCalls;
      in
        script;
  };
}
