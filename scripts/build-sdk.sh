#!/usr/bin/env bash
set -euo pipefail

OPENWRT_VERSION="${OPENWRT_VERSION:-24.10.0}"
TARGET="${TARGET:-ramips}"
SUBTARGET="${SUBTARGET:-mt7621}"
PROFILE="${PROFILE:-xiaomi_mi-router-ac2100}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/build}"
SDK_BASENAME="${SDK_BASENAME:-openwrt-sdk-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}_gcc-13.3.0_musl.Linux-x86_64}"
SDK_ARCHIVE="${SDK_BASENAME}.tar.zst"
SDK_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}/${SDK_ARCHIVE}"
SDK_DIR="$WORK_DIR/$SDK_BASENAME"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [ ! -f "$SDK_ARCHIVE" ]; then
  echo "Downloading SDK: $SDK_URL"
  curl -fL --retry 3 -o "$SDK_ARCHIVE" "$SDK_URL"
fi

if [ ! -d "$SDK_DIR" ]; then
  echo "Extracting SDK: $SDK_ARCHIVE"
  tar --use-compress-program=unzstd -xf "$SDK_ARCHIVE"
fi

cd "$SDK_DIR"
mkdir -p package
rm -rf package/netbird
cp -a "$ROOT_DIR/package/netbird" package/netbird

# Ensure the target profile exists in the release metadata. The SDK builds packages by arch,
# but this check prevents using the wrong OpenWrt target for the requested router.
curl -fsSL "https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}/profiles.json" \
  | jq -e --arg profile "$PROFILE" '.profiles[$profile] != null' >/dev/null

make defconfig
make package/netbird/{clean,compile} V=s

printf '\nBuilt packages:\n'
find bin/packages bin/targets -name 'netbird_*.ipk' -print
