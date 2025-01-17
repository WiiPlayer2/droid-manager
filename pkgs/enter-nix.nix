{ lib
, inputs
, system

, writeShellScript

, nix
}:
with lib;
let
  proot-static = inputs.self.packages.${system}.proot-static;
in
writeShellScript
"enter-nix"
''
  /sdcard/.${removePrefix "/" proot-static}/bin/proot-static -n /sdcard/.nix:/nix "$@"
''
