#!@bash@/bin/bash

set -e

CONFIGURATION=$1

# Add  --system aarch64-linux if it's not working
nix build .#droidManagerConfigurations.$CONFIGURATION
trap "rm ./result" EXIT
./result/bin/activate
