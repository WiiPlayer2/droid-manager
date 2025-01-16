{ pkgs
, nix-bundle
, nix-on-droid
, nixpkgs
, self
}:
drv:
let
  lib = pkgs.lib;

  # https://github.com/nix-community/nix-bundle/blob/4f6330b20767744a4c28788e3cdb05e02d096cd8/flake.nix
  getExe =
    x:
    pkgs.lib.getExe' x (
      x.meta.mainProgram or (pkgs.lib.warn
        "nix-bundle: Package ${
          pkgs.lib.strings.escapeNixIdentifier x.meta.name or x.pname or x.name
        } does not have the meta.mainProgram attribute. Assuming you want '${pkgs.lib.getName x}'."
        pkgs.lib.getName
        x
      )
    );

  programPath = getExe drv;

  crossArgs = {
    system = pkgs.system;
    crossSystem =
      let
        arch = lib.strings.removeSuffix "-linux" pkgs.system;
      in
      {
        config = "${arch}-unknown-linux-android";
        sdkVerVersion = "32";
        libc = "bionic";
        useAndroidPrebuilt = false;
        useLLVM = true;
        isStatic = true;
      };
  };
  pkgsCross-imported = import nixpkgs crossArgs;
  pkgsCross-patched = pkgsCross-imported.applyPatches {
    name = "nixpkgs-crosscompilation-patched";
    src = nixpkgs;
    patches = [
      "${nix-on-droid}/pkgs/cross-compiling/compiler-rt.patch"
      "${nix-on-droid}/pkgs/cross-compiling/libunwind.patch"
    ];
  };
  pkgsCross = import pkgsCross-patched crossArgs;
  stdenv = pkgsCross.stdenvAdapters.makeStaticBinaries pkgsCross.stdenv;

  talloc = self.packages.${pkgs.system}.talloc-static;
  # prootTermux = (pkgsCross.callPackage "${nix-on-droid}/pkgs/proot-termux" {
  #   inherit stdenv;
  # }).overrideAttrs {
  #   buildInputs = [
  #     talloc
  #     pkgs.glibc.static
  #   ];
  # };
  prootTermux = nix-on-droid.packages.aarch64-linux.prootTermux-aarch64;

  script = pkgs.writeScript "startup-script" ''
    #!/bin/sh
    .${prootTermux}/bin/proot-static -b ./nix:/nix ${programPath} "$@"
  '';

  nix-bundle-fun =
    drv:
    nix-bundle.makebootstrap {
      drvToBundle = drv;
      # targets = [ script ];
      targets = [ script ];
      startup = ".${builtins.unsafeDiscardStringContext script} '\"$@\"'";
    };

  bundled = nix-bundle-fun drv;

  sed = "${pkgs.gnused}/bin/sed";

  sedScript = pkgs.writeText "android-shell-sed-script" ''
    0,/hexdump/{s/hexdump.*urandom/dd if=\/dev\/urandom bs=4 count=1 2>\/dev\/null | base64/}
    0,/tmpdir=\/$HOME\/.cache/{s/tmpdir=\/$HOME\/.cache/tmpdir=\/sdcard\/.cache/}

    62s/.*/  [ -f \/tmp\/env-$hash ] || unpack_env > \/tmp\/env-$hash/
    63s/.*/  [ -f \/tmp\/run-$hash ] || unpack_run > \/tmp\/run-$hash/
    64s/.*/  chmod ug+x \/tmp\/run-$hash/
    65,70s/dat/\/tmp\/dat-$hash/
    75s/..\/env/\/tmp\/env-$hash/
    75s/..\/run/\/tmp\/run-$hash/

    # 0,/unset/{s/-e/-x -e/}
  '';
in
pkgs.runCommandLocal
  "${drv.name}-android"
  {}
  ''
    ${sed} -f ${sedScript} ${bundled} > $out
    # cp ${bundled} $out
    chmod +x $out
  ''
