#!/usr/bin/env bash
#
# bootstrap.sh - Interactive installer for popup
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/poplanguage/popup/master/scripts/bootstrap.sh | bash
#
set -euo pipefail

readonly REPO="poplanguage/popup"
readonly GITHUB_API="https://api.github.com"
readonly INSTALL_DIR="$HOME/.popup"
readonly BIN_DIR_NAME="bin"

TEMP_DIR=""

info()  { printf "=> %s\n" "$*"; }
error() { printf "=> error: %s\n" "$*" >&2; }
die()   { error "$@"; exit 1; }

cleanup() {
    if [ -d "${TEMP_DIR:-}" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

make_temp_dir() {
    TEMP_DIR=$(mktemp -d) || die "could not create temporary directory"
    chmod 700 "$TEMP_DIR"
}

detect_platform() {
    local arch os

    arch=$(uname -m 2>/dev/null) || die "could not detect architecture"
    os=$(uname -s 2>/dev/null) || die "could not detect OS"

    case "$arch" in
        x86_64|amd64)   ARCH="x86_64" ;;
        aarch64|arm64)  ARCH="aarch64" ;;
        *) die "unsupported architecture: $arch" ;;
    esac

    case "$os" in
        Linux)  OS="linux" ;;
        Darwin) OS="darwin" ;;
        *) die "unsupported OS: $os" ;;
    esac

    PLATFORM="${ARCH}-unknown-${OS}-gnu"
    info "detected platform: $PLATFORM"
}

github_get() {
    local url="$1"
    curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$url"
}

resolve_version() {
    info "resolving latest version..."
    local releases
    releases=$(github_get "$GITHUB_API/repos/$REPO/releases") || \
        die "could not fetch releases from GitHub"

    VERSION=$(printf '%s' "$releases" | \
        grep -o '"tag_name":"[^"]*"' | \
        head -1 | \
        sed 's/"tag_name":"//;s/"//') || \
        die "could not parse version from releases"

    [ -n "$VERSION" ] || die "no releases found"
    info "latest version: $VERSION"
}

download_binary() {
    local url="$GITHUB_API/repos/$REPO/releases/tags/$VERSION"
    local response asset_url

    info "fetching release metadata for $VERSION..."
    response=$(github_get "$url") || \
        die "could not fetch release $VERSION"

    asset_url=$(printf '%s' "$response" | \
        grep -o '"browser_download_url":"[^"]*' | \
        grep "$PLATFORM" | \
        head -1 | \
        sed 's/"browser_download_url":"//') || \
        true

    [ -n "$asset_url" ] || \
        die "no asset found for platform $PLATFORM in release $VERSION"

    info "downloading: $asset_url"
    curl -fSL -o "$TEMP_DIR/popup" "$asset_url" || \
        die "download failed"

    chmod +x "$TEMP_DIR/popup"
    info "download complete"
}

do_install() {
    local bin_dir="$INSTALL_DIR/$BIN_DIR_NAME"

    detect_platform
    resolve_version
    download_binary

    info "installing to $INSTALL_DIR..."
    mkdir -p "$bin_dir" || die "could not create $bin_dir"

    mv "$TEMP_DIR/popup" "$bin_dir/popup" || \
        die "could not move binary to $bin_dir"

    TEMP_DIR=""

    info "installed: $bin_dir/popup"
    ensure_path "$bin_dir"
}

ensure_path() {
    local dir="$1"

    case ":$PATH:" in
        *":$dir:"*)
            info "$dir is already in PATH"
            return
            ;;
    esac

    info ""
    info "Add popup to your PATH by appending one of the following to your shell profile:"
    info ""
    info "  bash (~/.bashrc):"
    info "    export PATH=\"$dir:\$PATH\""
    info ""
    info "  zsh (~/.zshrc):"
    info "    export PATH=\"$dir:\$PATH\""
    info ""
    info "  fish (~/.config/fish/config.fish):"
    info "    fish_add_path $dir"
    info ""
}

do_uninstall() {
    if [ ! -d "$INSTALL_DIR" ]; then
        info "installation directory not found: $INSTALL_DIR"
        info "nothing to uninstall"
        return
    fi

    info "removing $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR" || die "could not remove $INSTALL_DIR"
    info "uninstalled popup"
    info ""
    info "You may also remove the PATH entry for $INSTALL_DIR/$BIN_DIR_NAME from your shell profile."
}

show_menu() {
    local installed=0
    if [ -d "$INSTALL_DIR" ]; then
        installed=1
    fi

    printf "\n"
    printf "popup - Pop Language Toolchain Manager\n"
    printf "========================================\n\n"

    if [ "$installed" -eq 1 ]; then
        printf "  [1] Install (reinstall)\n"
        printf "  [2] Uninstall\n"
        printf "  [3] Exit\n\n"
    else
        printf "  [1] Install\n"
        printf "  [2] Exit\n\n"
    fi

    printf "Select an option: "
}

read_choice() {
    local installed=0
    if [ -d "$INSTALL_DIR" ]; then
        installed=1
    fi

    read -r choice

    case "$choice" in
        1)
            make_temp_dir
            do_install
            ;;
        2)
            if [ "$installed" -eq 1 ]; then
                do_uninstall
            else
                info "exiting"
                exit 0
            fi
            ;;
        3)
            if [ "$installed" -eq 1 ]; then
                info "exiting"
                exit 0
            else
                error "invalid option: $choice"
                show_menu
                read_choice
            fi
            ;;
        *)
            error "invalid option: $choice"
            show_menu
            read_choice
            ;;
    esac
}

main() {
    command -v curl >/dev/null 2>&1 || die "curl is required but not found"

    show_menu
    read_choice
}

main
