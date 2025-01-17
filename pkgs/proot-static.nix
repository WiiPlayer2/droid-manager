{ inputs
, system
, lib
}:
lib.warn
"proot-static is currently just x86_64-linux.prootTermux-aarch64 from nix-on-droid"
inputs.nix-on-droid.packages.x86_64-linux.prootTermux-aarch64
