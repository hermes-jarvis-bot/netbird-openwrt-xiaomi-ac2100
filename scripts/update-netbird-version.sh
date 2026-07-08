#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAKEFILE="$ROOT_DIR/package/netbird/Makefile"
TAG="${1:-latest}"

if [ "$TAG" = "latest" ]; then
  TAG="$(curl -fsSL https://api.github.com/repos/netbirdio/netbird/releases/latest | jq -r .tag_name)"
fi
VERSION="${TAG#v}"
ASSET="netbird_${VERSION}_linux_mipsle_softfloat.tar.gz"
CHECKSUMS_URL="https://github.com/netbirdio/netbird/releases/download/v${VERSION}/netbird_${VERSION}_checksums.txt"
HASH="$(curl -fsSL "$CHECKSUMS_URL" | awk -v asset="$ASSET" '$2 == asset {print $1}')"

if [ -z "$HASH" ]; then
  echo "Could not find checksum for $ASSET in $CHECKSUMS_URL" >&2
  exit 1
fi

python3 - "$MAKEFILE" "$VERSION" "$HASH" <<'PY'
import re
import sys
from pathlib import Path

makefile = Path(sys.argv[1])
version = sys.argv[2]
hash_value = sys.argv[3]

text = makefile.read_text()
old_version_match = re.search(r'^PKG_VERSION:=(.*)$', text, flags=re.M)
old_version = old_version_match.group(1).strip() if old_version_match else None
text = re.sub(r'^PKG_VERSION:=.*$', f'PKG_VERSION:={version}', text, flags=re.M)
text = re.sub(r'^PKG_HASH:=.*$', f'PKG_HASH:={hash_value}', text, flags=re.M)
if old_version != version:
    text = re.sub(r'^PKG_RELEASE:=.*$', 'PKG_RELEASE:=1', text, flags=re.M)
release_match = re.search(r'^PKG_RELEASE:=(.*)$', text, flags=re.M)
release = release_match.group(1).strip() if release_match else '1'
makefile.write_text(text)
PY

echo "Updated netbird package to v${VERSION} (${HASH})"
