#!/usr/bin/env bash
# Local shim for iso building (Probably not the best way but documentation for this kinda stuff is... Well i cant find it!)
set -euo pipefail

TITANOBOA_REF="${TITANOBOA_REF:-5c457c3d0518bd17e754be0fd98a60d29d26abb4}"
installer_image="$1"
output_dir="${2:-output}"

if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=()
else
    SUDO=(sudo)
fi

mkdir -p "$output_dir"
output_abs="$(realpath "$output_dir")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

curl -fsSL \
    "https://raw.githubusercontent.com/ublue-os/titanoboa/${TITANOBOA_REF}/main.sh" \
    -o "$tmpdir/main.sh"
curl -fsSL \
    "https://raw.githubusercontent.com/ublue-os/titanoboa/${TITANOBOA_REF}/build_iso.sh" \
    -o "$tmpdir/build_iso.sh"

chmod +x "$tmpdir/main.sh" "$tmpdir/build_iso.sh"

"${SUDO[@]}" env \
    TITANOBOA_CTR_IMAGE="$installer_image" \
    TITANOBOA_OUTPUT_DIR="$output_abs" \
    bash -eo pipefail "$tmpdir/main.sh"

test -n "$(find "$output_abs" -maxdepth 1 -name '*.iso' -print -quit)"

"${SUDO[@]}" chown -R "$(id -u):$(id -g)" "$output_abs"
