{ lib
, fetchurl
}:
let
  inherit (lib)
    removeSuffix
    ;
in
{ name
, revision
, repo ? "https://f-droid.org/repo/"
, hash ? ""
}:
let
  fixedRepo = removeSuffix "/" repo;
  fullUrl = "${repo}/${name}_${revision}.apk";
  fetchedApk = fetchurl {
    url = fullUrl;
    inherit hash;
  };
  enrichedApk = fetchedApk // {
    meta = fetchedApk.meta // {
      pname = name;
    };
  };
in
  enrichedApk
