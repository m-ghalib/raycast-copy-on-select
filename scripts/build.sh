#!/usr/bin/env bash
# Builds the native daemon and stages it inside the Raycast extension.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="raycast-extension/assets/copyonselectd"
ARCHS=(--arch arm64 --arch x86_64)

echo "==> Building universal binary"
if ! swift build -c release --package-path macos-helper "${ARCHS[@]}" >/dev/null 2>&1; then
  echo "    WARNING: the universal build failed. Falling back to a native-only build."
  ARCHS=()
  swift build -c release --package-path macos-helper >/dev/null
fi
BIN="$(swift build -c release --package-path macos-helper "${ARCHS[@]}" --show-bin-path)/copyonselectd"
cp "$BIN" "$OUT"

if [ -n "${SIGN_IDENTITY:-}" ]; then
  echo "==> Signing with \$SIGN_IDENTITY"
  codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp "$OUT"
else
  echo "==> Signing ad hoc (local use; permissions reset when the binary changes)"
  codesign --force --sign - "$OUT"
fi
codesign --verify --strict "$OUT"

chmod +x "$OUT"
shasum -a 256 "$OUT" | awk '{print $1}' > "$OUT.sha256"

echo "==> Done"
echo "    binary: $OUT ($(stat -f%z "$OUT") bytes)"
echo "    arch:   $(lipo -archs "$OUT")"
echo "    sha256: $(cat "$OUT.sha256")"
