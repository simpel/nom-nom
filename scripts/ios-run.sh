#!/usr/bin/env bash
# Builds NomNom for the iOS Simulator, installs it and launches it. No Xcode window needed.
#
#   pnpm ios                        # booted simulator, or the first available iPhone
#   pnpm ios --device "iPhone 17"   # a named simulator
#   pnpm ios:install                # build and install only
#
# Hot reload: needs InjectionNext.app in /Applications (started here if not running).
# The app is launched with INJECTION_PROJECT_ROOT, so every save under apps/ios is injected.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS_DIR="$ROOT/apps/ios"
PROJECT="$IOS_DIR/NomNom.xcodeproj"
SCHEME="NomNom"
DEVICE_NAME=""
LAUNCH=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE_NAME="$2"; shift 2 ;;
    --no-launch) LAUNCH=0; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Pick a simulator: the named one, else the booted one, else the first available iPhone.
if [[ -n "$DEVICE_NAME" ]]; then
  UDID="$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)"
else
  UDID="$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1 || true)"
  [[ -z "$UDID" ]] && UDID="$(xcrun simctl list devices available | grep -E '^\s+iPhone' | head -1 | grep -oE '[0-9A-F-]{36}' || true)"
fi
[[ -z "$UDID" ]] && { echo "No matching simulator found. List them with: xcrun simctl list devices available" >&2; exit 1; }

xcrun simctl boot "$UDID" 2>/dev/null || true
# Show the simulator window: Simulator.app up to Xcode 26, DeviceHub.app from Xcode 27.
XCODE_APP="$(xcode-select -p)/.."
for app in "$XCODE_APP/Developer/Applications/Simulator.app" "$XCODE_APP/Applications/DeviceHub.app"; do
  [[ -d "$app" ]] && { open "$app"; break; }
done

echo "Building $SCHEME for simulator $UDID..."
# Default DerivedData on purpose: InjectionNext reads the build log from there.
BUILD_LOG="$(mktemp -t nomnom-build)"
if ! xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "id=$UDID" \
    -quiet >"$BUILD_LOG" 2>&1; then
  grep -E "error:" "$BUILD_LOG" | sort -u >&2 || true
  echo "Build failed. Full log: $BUILD_LOG" >&2
  exit 1
fi

SETTINGS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination "id=$UDID" -showBuildSettings 2>/dev/null)"
APP_PATH="$(awk -F' = ' '/ TARGET_BUILD_DIR =/{d=$2} / FULL_PRODUCT_NAME =/{n=$2} END{print d"/"n}' <<<"$SETTINGS")"
BUNDLE_ID="$(awk -F' = ' '/ PRODUCT_BUNDLE_IDENTIFIER =/{print $2; exit}' <<<"$SETTINGS")"

echo "Installing $APP_PATH..."
xcrun simctl install "$UDID" "$APP_PATH"

[[ $LAUNCH -eq 0 ]] && { echo "Installed $BUNDLE_ID."; exit 0; }

if ! pgrep -xq InjectionNext && [[ -d /Applications/InjectionNext.app ]]; then
  # autoLaunchXcode would reopen Xcode and break the file watcher.
  open -g -a InjectionNext --args -autoLaunchXcode NO
fi

echo "Launching $BUNDLE_ID. App logs and hot reload results stream below; Ctrl-C to stop."
SIMCTL_CHILD_INJECTION_PROJECT_ROOT="$IOS_DIR" \
  xcrun simctl launch --console-pty --terminate-running-process "$UDID" "$BUNDLE_ID"
