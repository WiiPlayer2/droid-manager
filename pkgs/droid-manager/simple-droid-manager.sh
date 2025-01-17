#!@bash@/bin/bash

set -e

CONFIGURATION=$1

nix bundle --bundler .#androidShell .#droidManagerConfigurations.$CONFIGURATION
trap "rm droid-manager-generation-android 2>/dev/null || true" EXIT
adb push droid-manager-generation-android /tmp/droid-manager-activate
rm droid-manager-generation-android
adb shell /tmp/droid-manager-activate
