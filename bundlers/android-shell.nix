{ system
, nix-bundle
, nix-on-droid
, nixpkgs
, self
, self'
}:
drv:
let
  pkgs = import nixpkgs {
    inherit system;
  };
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

  prootPkg = self'.packages.proot-static;

  script = pkgs.writeScript "startup-script" ''
    #!/bin/sh
    .${prootPkg}/bin/proot-static -b ./nix:/nix ${programPath} "$@"
  '';

  fix-drv-pname =
    with lib;
    drv:
    if hasAttr "pname" drv
    then drv
    else drv.overrideAttrs {
      pname = drv.name;
    };
  nix-bundle-imported = import nix-bundle { nixpkgs = pkgs; };
  nix-bundle-fun =
    drv:
    nix-bundle-imported.makebootstrap {
      drvToBundle = fix-drv-pname drv;
      targets = [ script drv ];
      startup = ".${builtins.unsafeDiscardStringContext script} '\"$@\"'";
    };

  bundled = nix-bundle-fun drv;

  sed = "${pkgs.gnused}/bin/sed";

  sedScript = pkgs.writeText "android-shell-sed-script" ''
    0,/hexdump/{s/hexdump.*urandom/dd if=\/dev\/urandom bs=4 count=1 2>\/dev\/null | base64/}
    0,/tmpdir=\/$HOME\/.cache/{s/tmpdir=\/$HOME\/.cache/tmpdir=\/tmp\/.cache/}

    62s/.*/  [ -f \/tmp\/env ] || unpack_env > \/tmp\/env/
    63s/.*/  [ -f \/tmp\/run ] || unpack_run > \/tmp\/run/
    64s/.*/  chmod ug+x \/tmp\/run/
    65,70s/dat/\/tmp\/dat/
    75s/..\/env/\/tmp\/env/
    75s/..\/run/\/tmp\/run/

    # 0,/unset/{s/-e/-x -e/}
  '';
in
pkgs.runCommandLocal
  "${drv.pname or drv.name or "bundled"}-android"
  {}
  ''
    ${sed} -f ${sedScript} ${bundled} > $out
    chmod +x $out
  ''
