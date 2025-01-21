{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.environment.files;

  mkFilesOption = description: mkOption {
    inherit description;
    type = with types; attrsOf (submodule {
      options = {
        content = mkOption {
          description = "The file content";
          type = nullOr str;
          default = null;
        };

        source = mkOption {
          description = "The file content source";
          type = nullOr pathInStore;
          default = null;
        };

        updateMethod = mkOption {
          description = "The update method to use";
          type = enum [
            "copy"
            "json-merge"
          ];
          default = "copy";
        };

        needsRoot = mkEnableOption "This file needs root to be installed/updated.";
      };
    });
    default = {};
  };
in
{
  options.environment.files = {
    root = mkFilesOption "Files in /";
  };

  config = {
    build.activation.device.default =
    let
      getFilePath =
        { name, value }:
        if value.source != null && value.content != null
        then throw "Source and content are set for '${name}'"
        else if value.source == null && value.content == null
        then throw "Exactly one of source or content must be set for '${name}'."
        else if value.source != null
        then value.source
        else pkgs.writeText name value.content;
      updaters =
        from: to:
        {
          copy = ''
            cp -v ${from} '${to}'
          '';

          json-merge = ''
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' '${to}' ${from} | ${pkgs.moreutils}/bin/sponge '${to}'
          '';
        };
      mkUpdateFile =
        { name, value } @ file:
        ''
          mkdir -p $(dirname '${name}')
          ${(updaters (getFilePath file) name).${value.updateMethod}}
        '';
      fileUpdates =
        rooted:
        concatStringsSep
        "\n"
        (
          map
          mkUpdateFile
          (
            filter
            ({ value, ... }: value.needsRoot == rooted)
            (attrsToList cfg.root)
          )
        );
      mkUpdateScript =
        rooted:
        ''
          set -e
          ${fileUpdates rooted}
        '';
    in
    {
      update-files.script = mkUpdateScript false;
      update-files-rooted = {
        script = mkUpdateScript true;
        needsRoot = true;
      };
    };
  };
}
