#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/ImanolBarba/Hyprspace/"
SRC_DIR="${HYPRSPACE_SRC:-${HOME}/dotfiles/hyprspace}"
PATCH_DIR="${HYPRSPACE_PATCHES:-${HOME}/dotfiles/hyprspace-patches}"
PLUGIN="${SRC_DIR}/Hyprspace.so"
XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
BACKUP="${XDG_STATE_HOME}/hyprspace/Hyprspace.so.bak"

die() { echo "error: $*" >&2; exit 1; }

pin_for() {
    case "$1" in
        0.50) echo "0a82e3724f929de8ad8fb04d2b7fa128493f24f7" ;;
        0.55) echo "3624878a7b6c00dfa77e351438fa209df99ad81d" ;;
        0.56) echo "96a3b958a05a8942d26a5ec510f60217d63a7dce" ;;
        *)    return 1 ;;
    esac
}

command -v hyprctl >/dev/null || die "hyprctl not found - run this inside a Hyprland session"
command -v git     >/dev/null || die "git not found"
command -v make    >/dev/null || die "make not found - sudo dnf install make gcc"

echo "Detecting Hyprland version"
TAG="$(hyprctl version -j | jq -r '.tag')"
[ -n "$TAG" ] && [ "$TAG" != "null" ] || die "could not read version from hyprctl"
MINOR="$(echo "$TAG" | sed -E 's/^v?([0-9]+\.[0-9]+).*/\1/')"
echo "  running Hyprland ${TAG} (series ${MINOR})"

COMMIT="$(pin_for "$MINOR")" || die "no Hyprspace pin known for Hyprland ${MINOR} - add one to pin_for()"
echo "  pinning Hyprspace to ${COMMIT:0:12}"

if ! pkg-config --exists hyprland; then
    if [ -d "${XDG_DATA_HOME}/hyprpm/headersRoot/share/pkgconfig" ]; then
        export PKG_CONFIG_PATH="${XDG_DATA_HOME}/hyprpm/headersRoot/share/pkgconfig"
        echo "  using hyprpm headers"
    else
        die "hyprland headers not found - sudo dnf install hyprland-devel"
    fi
fi

if [ ! -d "${SRC_DIR}/.git" ]; then
    echo "Cloning Hyprspace"
    git clone "$REPO_URL" "$SRC_DIR"
else
    echo "Fetching Hyprspace"
    git -C "$SRC_DIR" fetch --all --tags --quiet
fi

[ -z "$(git -C "$SRC_DIR" status --porcelain)" ] \
    || die "${SRC_DIR} has uncommitted changes - commit or stash them first"

echo "Checking out pinned commit"
git -C "$SRC_DIR" checkout --quiet --detach "$COMMIT"

shopt -s nullglob
PATCHES=("$PATCH_DIR"/*.patch)
shopt -u nullglob

BUILD=""
APPLIED=0
# the tree is left exactly as the pin describes, patched only for the length of the
# build, so the guard above stays meaningful and disabling a patch needs no undo step
cleanup() {
    [ -n "$BUILD" ] && rm -rf "$BUILD"
    while [ "$APPLIED" -gt 0 ]; do
        APPLIED=$(( APPLIED - 1 ))
        git -C "$SRC_DIR" apply -R "${PATCHES[APPLIED]}" 2>/dev/null || true
    done
}
trap cleanup EXIT

if [ ${#PATCHES[@]} -gt 0 ]; then
    echo "Applying ${#PATCHES[@]} patch(es)"
    for p in "${PATCHES[@]}"; do
        echo "  $(basename "$p")"
        git -C "$SRC_DIR" apply --check "$p" || die "patch does not apply against ${COMMIT:0:12}: $p"
        git -C "$SRC_DIR" apply "$p"
        APPLIED=$(( APPLIED + 1 ))
    done
else
    echo "No patches in ${PATCH_DIR} - building stock"
fi

echo "Building"
BUILD="$(mktemp -d)"
make -C "$SRC_DIR" all TARGET="${BUILD}/Hyprspace.so"
[ -s "${BUILD}/Hyprspace.so" ] || die "build produced nothing"

echo "Installing"
# never cp onto a mapped .so - that truncates it under the running compositor.
# unload first, then rename, which swaps the dentry and leaves the old inode alone.
hyprctl plugin unload "$PLUGIN" >/dev/null 2>&1 || true
if [ -f "$PLUGIN" ]; then
    mkdir -p "$(dirname "$BACKUP")"
    cp -f "$PLUGIN" "$BACKUP"
fi
mv -f "${BUILD}/Hyprspace.so" "$PLUGIN"
hyprctl plugin load "$PLUGIN" >/dev/null

sleep 0.5
hyprctl plugin list | grep -qi hyprspace || die "plugin failed to load - previous build saved at ${BACKUP}"
echo "  loaded from ${PLUGIN}"

STRUT="$(hyprctl getoption plugin:overview:affectStrut | awk '/^int:/{print $2}')"
if [ "$STRUT" != "0" ]; then
    echo
    echo "warning: plugin:overview:affectStrut is ${STRUT}."
    echo "  It overwrites the monitor's whole reserved area, permanently dropping the"
    echo "  exclusive zone of any layer that does not re-assert one (nwg-dock -x)."
    echo "  Set it to 0 in hyprland.conf unless you have applied a patch for it."
fi

DOCK="$(pgrep -af 'nwg-dock-hyprland' | head -1 | cut -d' ' -f2-)"
if [ -n "$DOCK" ]; then
    BOTTOM="$(hyprctl monitors -j | jq -r '.[0].reserved[3]')"
    if [ "$BOTTOM" = "0" ]; then
        echo "Restoring nwg-dock reserved area"
        pkill -x nwg-dock-hyprland || true
        sleep 0.5
        hyprctl dispatch exec "$DOCK" >/dev/null
    fi
fi

echo "Done. Bind it with: bind = \$mainMod, TAB, overview:toggle"
