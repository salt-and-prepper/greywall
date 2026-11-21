#!/usr/bin/env bash
# Build the tun2socks binaries greywall embeds (internal/sandbox/bin/), from
# source, instead of downloading upstream's release builds (FORK.md). Pins the
# tun2socks commit and the golang.org/x modules it links, and builds with the
# Go toolchain from greywall's go.mod, so the embedded binaries carry current
# dependencies and can be rebuilt reproducibly.
#
# usage: scripts/build-tun2socks.sh [out-dir]   (default internal/sandbox/bin)
set -euo pipefail

TUN2SOCKS_REPO="https://github.com/xjasonlyu/tun2socks.git"
TUN2SOCKS_TAG="v2.7.0"
TUN2SOCKS_COMMIT="8dda19e8e4613e014f0b12f3e624fdff5e5f23b3"
TUN2SOCKS_VERSION="v2.7.0-ellwood.1"
X_MODULES=(
  golang.org/x/crypto@v0.59.0
  golang.org/x/net@v0.63.0
  golang.org/x/sys@v0.50.0
  golang.org/x/text@v0.44.0
)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/internal/sandbox/bin}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"   # absolute: the build below runs in a temp checkout
TOOLCHAIN="$(awk '/^toolchain /{print $2}' "$ROOT/go.mod")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git -c advice.detachedHead=false clone -q --depth 1 --branch "$TUN2SOCKS_TAG" "$TUN2SOCKS_REPO" "$WORK/src"
got="$(git -C "$WORK/src" rev-parse HEAD)"
if [ "$got" != "$TUN2SOCKS_COMMIT" ]; then
  echo "tun2socks $TUN2SOCKS_TAG is $got, expected $TUN2SOCKS_COMMIT" >&2
  exit 1
fi

cd "$WORK/src"
export GOTOOLCHAIN="${TOOLCHAIN:-auto}" GOFLAGS=-mod=mod
go get "${X_MODULES[@]}" "toolchain@${TOOLCHAIN}"
go mod tidy

module="github.com/xjasonlyu/tun2socks/v2"
for arch in amd64 arm64; do
  CGO_ENABLED=0 GOOS=linux GOARCH="$arch" go build -trimpath \
    -ldflags "-w -s -buildid= -X ${module}/internal/version.Version=${TUN2SOCKS_VERSION} -X ${module}/internal/version.GitCommit=${TUN2SOCKS_COMMIT:0:7}" \
    -o "$OUT/tun2socks-linux-$arch" .
  chmod 0755 "$OUT/tun2socks-linux-$arch"
done
echo "tun2socks ${TUN2SOCKS_VERSION} built for linux/amd64 and linux/arm64 in $OUT"
