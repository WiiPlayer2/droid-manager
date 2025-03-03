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
in
fetchurl {
  url = fullUrl;
  inherit hash;
}
