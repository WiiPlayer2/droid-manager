{ lib, ...}:
let
  inherit (lib)
    map
    attrsToList;

  directory = ./by-name;
  entriesInDirectory = builtins.readDir directory;
  mkImportPath = { name, ... }: directory + "/${name}";
  imports =
    map
    mkImportPath
    (attrsToList entriesInDirectory);
in
{
  inherit imports;
}
