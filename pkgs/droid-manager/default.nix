{ lib
, runCommand

, bash
}:

runCommand
  "droid-manager"
  {
    preferLocalBuild = true;
    allowSubstitutes = false;
  }
  ''
    install -D -m755  ${./droid-manager.sh} $out/bin/droid-manager

    substituteInPlace $out/bin/droid-manager \
      --subst-var-by bash "${bash}"
  ''
