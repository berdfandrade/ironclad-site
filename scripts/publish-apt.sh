#!/usr/bin/env bash
# Adds .deb files to the APT repository served from apt/ and re-signs it.
#
#   scripts/publish-apt.sh path/to/ironclad_0.2.0-1_amd64.deb [...]
#
# Users install with:  apt install ironclad  (setup commands on docs.html#install)
set -euo pipefail
cd "$(dirname "$0")/../apt"

KEY=${IRONCLAD_APT_KEY:-64D23529D30FCC280BFDE974D4CE37E46F48DEFB}
POOL=pool/main/i/ironclad
BIN=dists/stable/main/binary-amd64

mkdir -p "$POOL" "$BIN"
for deb in "$@"; do
  dpkg-deb --field "$deb" Package | grep -qx ironclad || { echo "not an ironclad package: $deb" >&2; exit 1; }
  cp "$deb" "$POOL/"
done

apt-ftparchive packages pool > "$BIN/Packages"
gzip -9nkf "$BIN/Packages"

release=$(mktemp)
trap 'rm -f "$release"' EXIT
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin=Ironclad \
  -o APT::FTPArchive::Release::Label=Ironclad \
  -o APT::FTPArchive::Release::Suite=stable \
  -o APT::FTPArchive::Release::Codename=stable \
  -o APT::FTPArchive::Release::Architectures=amd64 \
  -o APT::FTPArchive::Release::Components=main \
  -o "APT::FTPArchive::Release::Description=Ironclad distributed key-value store" \
  release dists/stable > "$release"
cp "$release" dists/stable/Release

gpg --batch --yes --local-user "$KEY" --clearsign --output dists/stable/InRelease dists/stable/Release
gpg --batch --yes --local-user "$KEY" --armor --detach-sign --output dists/stable/Release.gpg dists/stable/Release
gpg --export "$KEY" > ironclad.gpg
gpg --armor --export "$KEY" > ironclad.asc

echo "repository updated:"
grep -E '^(Package|Version|Filename):' "$BIN/Packages"
