# # am broadcast -a com.example.droidmanagerapp.SET_WALLPAPER -n com.example.droidmanagerapp/.SetWallpaper --es WALLPAPER_FILE /tmp/bg.png | ( ! grep "result=-1" )
# { hostPkgs }:
# hostPkgs.x86_64-linux.androidenv.buildApp {
#   name = "droid-manager-app";
#   src = ./src;

#   # platformVersions = [ "24" ];
# }

# TODO: figure out how to build actual apk
{ hostPkgs
}:
hostPkgs.x86_64-linux.runCommand "droid-manager-app" {
  meta.pname = "com.example.droidmanagerapp";
} ''
  ln -s ${./app-debug.apk} $out
''
