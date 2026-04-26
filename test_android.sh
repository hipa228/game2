#!/bin/bash
# Quick test script for Android
# Assumes APK is already built at: ./Horror_Game_3D.apk

set -e

APK_FILE="./Horror_Game_3D.apk"
PACKAGE_NAME="com.example.horrorgame3d"

if [ ! -f "$APK_FILE" ]; then
    echo "Error: APK file not found: $APK_FILE"
    echo "Please build the APK first using Godot Editor (Export → Android)"
    exit 1
fi

# Get first available device
DEVICE_ID=$(adb devices | tail -n +2 | grep -v "offline" | awk '{print $1}' | head -n1)

if [ -z "$DEVICE_ID" ]; then
    echo "Error: No Android devices found. Connect a device or start an emulator."
    exit 1
fi

echo "Installing on device: $DEVICE_ID"
adb -s "$DEVICE_ID" install -r "$APK_FILE"

echo "Launching app..."
adb -s "$DEVICE_ID" shell am start -n "${PACKAGE_NAME}/com.godot.game.GodotApp"

echo "App launched. To see logs: adb logcat -s Godot"