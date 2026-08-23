#!/bin/bash
# Só gera APK com tudo verde — porta fechada no build local
set -e
echo "build.sh: validando 7 gates antes de exportar..."
godot --headless --import 2>&1 | tail -n 2
godot --headless --check-only 2>&1 | tail -n 2
bash ci/check-file-coverage.sh 2>&1 | tail -n 5
godot --headless --script addons/gut/gut_cmdln.gd -gexit 2>&1 | tail -n 10
echo "build.sh: tudo verde, exportando APK..."
export ANDROID_HOME=${ANDROID_HOME:-/home/codespace/android_sdk}
export ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-/home/codespace/android_sdk}
export JAVA_HOME=${JAVA_HOME:-/usr/local/sdkman/candidates/java/current}
export PATH=$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH
mkdir -p build
godot --headless --export-debug "Android" build/debug.apk
ls -lh build/debug.apk
echo "build.sh: APK gerado só com tudo verde"
