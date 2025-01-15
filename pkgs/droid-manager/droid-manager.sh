#!@bash@/bin/bash

# roughly based on https://github.com/nix-community/nix-on-droid/blob/5d88ff2519e4952f8d22472b52c531bb5f1635fc/nix-on-droid/nix-on-droid.sh

set -eu

function errorEcho() {
    >&2 echo "$@"
}

function doHelp() {
    echo "Usage: $0 [OPTION] COMMAND"
    echo
    echo "Options"
    echo
    echo "  -h|--help         Print this help"
    echo "  -n|--dry-run      Do a dry run, only prints what actions would be taken"
    echo "  -v|--verbose      Verbose output"
    echo "  -f|--file FILE    Path to config file"
    echo "  -F|--flake FLAKE  Path to flake and device name (e.g. path/to/flake#device),"
    echo "                    device 'default' will be used if no attribute name is given"
    echo
    echo "Options passed on to nix build"
    echo
    echo "  -I|--include PATH"
    echo "  --builders BUILDERS"
    echo "  --cores NUM"
    echo "  --keep-failed"
    echo "  --keep-going"
    echo "  --max-jobs NUM"
    echo "  --option NAME VALUE"
    echo "  --show-trace"
    echo
    echo "Commands"
    echo
    echo "  help            Print this help"
    echo
    echo "  build           Build configuration"
}


COMMAND=
FLAKE_CONFIG_URI=
PASSTHROUGH_OPTS=()

while [[ $# -gt 0 ]]; do
    opt="$1"
    shift
    case $opt in
        build|help)
            COMMAND="$opt"
            ;;

        -h|--help)
            doHelp
            exit 0
            ;;

        -F|--flake)
            PASSTHROUGH_OPTS+=(--extra-experimental-features "flakes nix-command")
            # add "nixOnDroidConfigurations." as prefix in attribute name, e.g.
            # /path/to/flake#device -> /path/to/flake#nixOnDroidConfigurations.device
            # if no attribute name given, use "default"
            if [[ "$1" =~ \# ]]; then
                FLAKE_CONFIG_URI="${1%#*}#droidManagerConfigurations.${1#*#}"
            else
                FLAKE_CONFIG_URI="${1}#droidManagerConfigurations.default"
            fi
            shift
            ;;
    esac
done

case $COMMAND in
    build)
        doBuild
        ;;

    help)
        doHelp
        ;;

    *)
        errorEcho "Unknown command: $COMMAND"
        doHelp >&2
        exit 1
        ;;
esac
