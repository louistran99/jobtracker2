#!/usr/bin/env bash
# Installs a pinned, checksum-verified XcodeGen into .tools/ so every machine
# (and CI) generates the Xcode project with the exact same version.
set -euo pipefail

version="$1"
sha256="$2"
dest="$3"

if [[ -x "$dest/bin/xcodegen" ]]; then
    exit 0
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

url="https://github.com/yonaskolb/XcodeGen/releases/download/${version}/xcodegen.zip"
echo "Downloading XcodeGen ${version}…"
curl --fail --silent --show-error --location "$url" --output "$workdir/xcodegen.zip"

echo "${sha256}  $workdir/xcodegen.zip" | shasum --algorithm 256 --check --status || {
    echo "error: checksum mismatch for $url" >&2
    exit 1
}

unzip -q "$workdir/xcodegen.zip" -d "$workdir/unzipped"
rm -rf "$dest"
mkdir -p "$(dirname "$dest")"
mv "$workdir/unzipped/xcodegen" "$dest"
"$dest/bin/xcodegen" --version
