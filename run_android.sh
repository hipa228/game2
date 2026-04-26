#!/bin/bash
# Android run script for Godot Horror Game 3D
# Usage: ./run_android.sh [apk_file] [device_id]

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="Threshold"
DEFAULT_APK="${PROJECT_NAME}.apk"
GODOT_CMD="godot"  # Change to path of Godot executable if not in PATH
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@17/17.0.18/libexec/openjdk.jdk/Contents/Home"
export ANDROID_SDK_ROOT="/Users/hipa/Library/Android/sdk"
export ANDROID_NDK_ROOT="/Users/hipa/Library/Android/sdk/ndk/30.0.14904198"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if adb is available
check_adb() {
    if ! command -v adb &> /dev/null; then
        print_error "adb not found. Please install Android SDK Platform-Tools."
        print_info "Download from: https://developer.android.com/studio/releases/platform-tools"
        exit 1
    fi
}

# List available devices/emulators
list_devices() {
    print_info "Available Android devices/emulators:"
    adb devices -l | tail -n +2 | while read line; do
        if [ -n "$line" ]; then
            device_id=$(echo "$line" | awk '{print $1}')
            device_name=$(echo "$line" | awk '{print $5}' | cut -d: -f2)
            device_state=$(echo "$line" | awk '{print $2}')
            echo "  ${GREEN}${device_id}${NC} - ${device_name} (${device_state})"
        fi
    done
}

# Export APK using Godot (optional)
export_apk() {
    local output_apk="$1"
    print_info "Exporting APK using Godot..."

    if ! command -v "$GODOT_CMD" &> /dev/null; then
        print_error "Godot executable not found at: $GODOT_CMD"
        print_info "Please set GODOT_CMD in this script to your Godot executable path."
        return 1
    fi

    local apk_name=$(basename "$output_apk")
    local abs_apk="$PROJECT_DIR/$apk_name"
    cd "$PROJECT_DIR"
    "$GODOT_CMD" --headless --export-debug "Android" "$abs_apk"
    cd -

    if [ $? -eq 0 ] && [ -f "$abs_apk" ]; then
        print_info "APK exported successfully: $abs_apk"
        return 0
    else
        print_error "APK export failed"
        return 1
    fi
}

# Install APK on device
install_apk() {
    local apk_file="$1"
    local device_id="$2"

    if [ ! -f "$apk_file" ]; then
        print_error "APK file not found: $apk_file"
        print_info "Trying to export APK first..."
        export_apk "$apk_file" || exit 1
    fi

    print_info "Installing APK on device: $device_id"

    if [ -n "$device_id" ]; then
        adb -s "$device_id" install -r "$apk_file"
    else
        adb install -r "$apk_file"
    fi

    if [ $? -eq 0 ]; then
        print_info "Installation successful"
        return 0
    else
        print_error "Installation failed"
        return 1
    fi
}

# Run the app
run_app() {
    local device_id="$1"
    local package_name="com.example.horrorgame3d"
    local activity_name="com.godot.game.GodotAppLauncher"

    print_info "Launching app: $package_name"

    if [ -n "$device_id" ]; then
        adb -s "$device_id" shell am start -n "${package_name}/${activity_name}"
    else
        adb shell am start -n "${package_name}/${activity_name}"
    fi

    if [ $? -eq 0 ]; then
        print_info "App launched successfully"
        return 0
    else
        print_error "Failed to launch app"
        return 1
    fi
}

# Show logcat output
show_logs() {
    local device_id="$1"
    print_info "Showing logcat output (Ctrl+C to stop)..."

    if [ -n "$device_id" ]; then
        adb -s "$device_id" logcat -s "Godot"
    else
        adb logcat -s "Godot"
    fi
}

# Main script
main() {
    check_adb

    # Parse arguments
    APK_FILE="${1:-$DEFAULT_APK}"
    DEVICE_ID="$2"

    print_info "Project: $PROJECT_NAME"
    print_info "APK file: $APK_FILE"

    # List devices if no device specified
    if [ -z "$DEVICE_ID" ]; then
        list_devices
        print_warn "No device ID specified. Using first available device."
        DEVICE_ID=$(adb devices | tail -n +2 | grep -v "offline" | awk '{print $1}' | head -n1)

        if [ -z "$DEVICE_ID" ]; then
            print_error "No Android devices found. Please connect a device or start an emulator."
            exit 1
        fi
        print_info "Auto-selected device: $DEVICE_ID"
    fi

    # Install APK
    install_apk "$APK_FILE" "$DEVICE_ID" || exit 1

    # Run app
    run_app "$DEVICE_ID" || exit 1

    # Optionally show logs
    read -p "Show logcat output? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_logs "$DEVICE_ID"
    fi
}

# Run main function
main "$@"