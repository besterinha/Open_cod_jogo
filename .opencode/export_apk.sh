#!/bin/bash
set -e
cd /workspaces/Open_cod_jogo

export ANDROID_HOME=$HOME/Android/Sdk
mkdir -p build

echo "=== Exporting APK ==="
godot --headless --export-debug "Android" build/project.apk 2>&1

echo "=== Done ==="
ls -lh build/project.apk 2>/dev/null || echo "APK not found — check errors above"
