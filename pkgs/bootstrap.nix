{ lib
, inputs
, system

, writeShellScriptBin
}:
with lib;
let
  enter-nix = inputs.self.packages.${system}.enter-nix;
in
writeShellScriptBin
"bootstrap"
''
  set -e -x
  cp -a /nix /sdcard/.nix
  ln -s ${enter-nix} /sdcard/.nix/enter-nix
''
