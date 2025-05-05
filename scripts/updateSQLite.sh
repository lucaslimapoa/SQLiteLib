#!/bin/bash

# Usage: ./scripts/updateSQLite.sh <sqlite_src_url> <expected_sha3_256_hash>

set -euo pipefail

usage() {
  echo "Usage: $0 <sqlite_src_url> <expected_sha3_256_hash>"
  echo "Example:"
  echo "  $0 https://www.sqlite.org/2025/sqlite-src-3490100.zip 44e372507df045760fab3be59d16644233d87a33ada83ed49027ee4579b5892d"
  exit 1
}

if [ "$#" -ne 2 ]; then
  usage
fi

SQLITE_URL="$1"
EXPECTED_HASH="$2"
ZIP_FILE="sqlite-src.zip"
SQLITE_DIR="sqlite"

echo "🔽 Downloading SQLite source from: $SQLITE_URL"
curl -L -o "$ZIP_FILE" "$SQLITE_URL"

echo "🔒 Verifying SHA3-256 hash using OpenSSL..."
DOWNLOADED_HASH=$(openssl dgst -sha3-256 "$ZIP_FILE" | awk '{print $2}')

if [ "$DOWNLOADED_HASH" != "$EXPECTED_HASH" ]; then
  echo "❌ Hash mismatch!"
  echo "Expected: $EXPECTED_HASH"
  echo "Actual:   $DOWNLOADED_HASH"
  exit 1
fi
echo "✅ Hash verification passed."

echo "🧹 Removing existing '$SQLITE_DIR/' directory..."
rm -rf "$SQLITE_DIR"
mkdir "$SQLITE_DIR"

echo "📦 Extracting contents into '$SQLITE_DIR/'..."
unzip -q "$ZIP_FILE" -d "$SQLITE_DIR"

# Flatten nested directory if present
NESTED_DIR=$(find "$SQLITE_DIR" -mindepth 1 -maxdepth 1 -type d)

if [ -d "$NESTED_DIR" ]; then
  echo "📁 Flattening nested directory..."
  shopt -s dotglob
  mv "$NESTED_DIR"/* "$SQLITE_DIR"/
  rmdir "$NESTED_DIR"
fi

echo "🧽 Cleaning up..."
rm -f "$ZIP_FILE"

# Output version
if [ -f "$SQLITE_DIR/VERSION" ]; then
  VERSION=$(cat "$SQLITE_DIR/VERSION")
  echo "🎉 SQLite version installed: $VERSION"
else
  echo "⚠️ Warning: VERSION file not found in $SQLITE_DIR"
fi

echo "✅ SQLite source successfully updated in '$SQLITE_DIR/'"