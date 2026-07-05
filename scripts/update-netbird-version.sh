#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAKEFILE="$ROOT_DIR/package/netbird/Makefile"
README="$ROOT_DIR/README.md"
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

python3 - "$MAKEFILE" "$README" "$VERSION" "$HASH" "$ASSET" <<'PY'
from pathlib import Path
import re
import sys

makefile = Path(sys.argv[1])
readme = Path(sys.argv[2])
version = sys.argv[3]
hash_value = sys.argv[4]
asset = sys.argv[5]

text = makefile.read_text()
text = re.sub(r'^PKG_VERSION:=.*$', f'PKG_VERSION:={version}', text, flags=re.M)
text = re.sub(r'^PKG_HASH:=.*$', f'PKG_HASH:={hash_value}', text, flags=re.M)
text = re.sub(r'^PKG_RELEASE:=.*$', 'PKG_RELEASE:=1', text, flags=re.M)
makefile.write_text(text)

if readme.exists():
    text = readme.read_text()
    text = re.sub(r'\| NetBird release \| `v[^`]+` \|', f'| NetBird release | `v{version}` |', text)
    text = re.sub(r'\| NetBird asset \| `netbird_[^`]+_linux_mipsle_softfloat\.tar\.gz` \|', f'| NetBird asset | `{asset}` |', text)
    text = re.sub(r'\| Asset SHA256 \| `[0-9a-f]{64}` \|', f'| Asset SHA256 | `{hash_value}` |', text)
    text = re.sub(r'netbird_[0-9]+\.[0-9]+\.[0-9]+-r1_mipsel_24kc\.ipk', f'netbird_{version}-r1_mipsel_24kc.ipk', text)
    readme.write_text(text)
PY

echo "Updated netbird package to v${VERSION} (${HASH})"
