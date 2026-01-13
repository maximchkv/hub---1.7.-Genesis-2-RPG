#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="/Users/max/Desktop/xcode projects/1.7. Genesis 2 RPG/1.7. Genesis 2 RPG.xcodeproj"
SCHEME="1.7. Genesis 2 RPG"

# Default simulator (can override by env SIM_NAME)
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"

# DerivedData (can override by env DERIVED_DATA_PATH)
# Default goes to user Library to avoid polluting the repo.
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData/Genesis2RPG_CLI}"

echo "[sim] Target simulator: ${SIM_NAME}"

# Find UDID for the simulator name (prefer Booted). Use grep/sed for macOS compatibility.
DEVICE_LINES="$(
  xcrun simctl list devices available |
    grep -F "${SIM_NAME} (" || true
)"

UDID="$(
  echo "${DEVICE_LINES}" |
    (grep -F "(Booted)" || true) |
    head -n 1 |
    sed -nE 's/.*\(([0-9A-F-]+)\).*/\1/p'
)"

if [[ -z "${UDID}" ]]; then
  UDID="$(
    echo "${DEVICE_LINES}" |
      head -n 1 |
      sed -nE 's/.*\(([0-9A-F-]+)\).*/\1/p'
  )"
fi

if [[ -z "${UDID}" ]]; then
  echo "[sim] ERROR: Could not find simulator named '${SIM_NAME}'."
  echo "[sim] Available devices:"
  xcrun simctl list devices available
  exit 1
fi

echo "[sim] Using UDID: ${UDID}"

echo "[sim] Booting (if needed)…"
xcrun simctl bootstatus "${UDID}" -b

echo "[sim] Opening Simulator…"
open -a Simulator --args -CurrentDeviceUDID "${UDID}" >/dev/null 2>&1 || true

# Simulator can transiently enter "Shutting Down" after switching devices.
# Ensure it's fully booted before proceeding.
echo "[sim] Ensuring simulator is ready…"
xcrun simctl bootstatus "${UDID}" -b

echo "[sim] Building (Debug)…"
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration Debug \
  -destination "id=${UDID}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  build

echo "[sim] Resolving app path + bundle id…"
BUILD_SETTINGS="$(
  xcodebuild \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration Debug \
    -destination "id=${UDID}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -showBuildSettings
)"

TARGET_BUILD_DIR="$(echo "${BUILD_SETTINGS}" | awk -F' = ' '/ TARGET_BUILD_DIR /{print $2; exit}')"
WRAPPER_NAME="$(echo "${BUILD_SETTINGS}" | awk -F' = ' '/ WRAPPER_NAME /{print $2; exit}')"
PRODUCT_BUNDLE_IDENTIFIER="$(echo "${BUILD_SETTINGS}" | awk -F' = ' '/ PRODUCT_BUNDLE_IDENTIFIER /{print $2; exit}')"

APP_PATH="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "[sim] ERROR: App not found at ${APP_PATH}"
  exit 1
fi

if [[ -z "${PRODUCT_BUNDLE_IDENTIFIER}" ]]; then
  echo "[sim] ERROR: Could not resolve PRODUCT_BUNDLE_IDENTIFIER"
  exit 1
fi

simctl_retry() {
  local attempts="${1}"
  shift
  local i=1
  while (( i <= attempts )); do
    if "$@"; then
      return 0
    fi
    echo "[sim] simctl failed (attempt ${i}/${attempts}). Retrying after bootstatus…"
    xcrun simctl boot "${UDID}" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "${UDID}" -b || true
    sleep 2
    i=$((i+1))
  done
  return 1
}

echo "[sim] Installing: ${APP_PATH}"
simctl_retry 5 xcrun simctl install "${UDID}" "${APP_PATH}"

echo "[sim] Launching: ${PRODUCT_BUNDLE_IDENTIFIER}"
simctl_retry 5 xcrun simctl terminate "${UDID}" "${PRODUCT_BUNDLE_IDENTIFIER}" >/dev/null 2>&1 || true
simctl_retry 5 xcrun simctl launch "${UDID}" "${PRODUCT_BUNDLE_IDENTIFIER}"

echo "[sim] Done."

