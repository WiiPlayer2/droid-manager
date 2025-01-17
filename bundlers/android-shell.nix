{ system
, nix-bundle
, nix-on-droid
, nixpkgs
, self
}:
drv:
let
  lib = pkgs.lib;
  # overlay = final: prev: {
  #   # talloc = prev.talloc.overrideAttrs {
  #   #   nativeBuildInputs = prev.talloc.drvAttrs.nativeBuildInputs ++ [
  #   #     prev.glibc
  #   #   ];
  #   # };
  #   talloc = prev.callPackage ../pkgs/talloc-static.nix {
  #     stdenv = prev.stdenvAdapters.makeStaticBinaries prev.stdenv;
  #   };
  #   prootTermux = (prev.callPackage "${nix-on-droid}/pkgs/proot-termux" {
  #     stdenv = prev.stdenvAdapters.makeStaticBinaries prev.stdenv;
  #   }).overrideAttrs {
  #     buildInputs = [
  #       prev.talloc
  #       prev.glibc.static
  #     ];
  #   };
  #   tzdata = prev.tzdata.overrideAttrs {
  #     # buildInputs = [
  #     #   prev.glibc.static
  #     # ];
  #     makeFlags = prev.tzdata.drvAttrs.makeFlags ++ [
  #       "CFLAGS+=-I${prev.glibc.static}/include"
  #     ];
  #   };
  #   zlib = prev.zlib.overrideAttrs {
  #     buildInputs = prev.zlib.drvAttrs.buildInputs ++ [
  #       prev.libgcc
  #     ];
  #     # makeFlags = prev.zlib.drvAttrs.makeFlags ++ [
  #     #   "CFLAGS+=-I${prev.glibc.static}/include"
  #     # ];
  #   };
  #   python3 = prev.python3.overrideAttrs {
  #     buildInputs = prev.python3.drvAttrs.buildInputs ++ [
  #       prev.libgcc
  #     ];
  #   };
  #   gobject-introspection =
  #     let
  #       pythonModules = pp: [
  #         pp.mako
  #         pp.markdown
  #         pp.setuptools
  #         pp.distutils
  #       ];
  #       buildPackagesPython3WithModules = prev.buildPackages.python3.withPackages pythonModules;
  #       buildPackagesWithPython3WithModules = prev.buildPackages // {
  #         python3 = buildPackagesPython3WithModules;
  #       };
  #       python3WithModules = prev.python3.withPackages pythonModules;
  #     in
  #       # prev.gobject-introspection.override {
  #       #   buildPackages = buildPackagesWithPython3WithModules;
  #       #   python3 = python3WithModules;
  #       # };
  #       # prev.gobject-introspection.overrideAttrs {
  #       #   nativeBuildInputs = [
  #       #     # buildPackagesPython3WithModules
  #       #   # ] ++ prev.gobject-introspection.drvAttrs.nativeBuildInputs ++ [
  #       #   #   buildPackagesPython3WithModules
  #       #   ];
  #       #   buildInputs = [
  #       #     # python3WithModules
  #       #   # ] ++ prev.gobject-introspection.drvAttrs.buildInputs ++ [
  #       #   #   python3WithModules
  #       #   ];
  #       # };
  #       {};
  # };
  pkgs = import nixpkgs {
    inherit system;
    # overlays = [ overlay ];
  };

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

  # pkgsAndroid = pkgs.pkgsCross.aarch64-android-prebuilt;
  prootPkg = nix-on-droid.packages.${system}.prootTermux-aarch64;
  # prootPkg = pkgsAndroid.proot.override {
  #   enablePython = false;
  #   stdenv = staticStdenv;
  # };

  script = pkgs.writeScript "startup-script" ''
    #!/bin/sh
    .${prootPkg}/bin/proot-static -b ./nix:/nix ${programPath} "$@"
  '';

  nix-bundle-imported = import nix-bundle { nixpkgs = pkgs; };
  nix-bundle-fun =
    drv:
    nix-bundle-imported.makebootstrap {
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
