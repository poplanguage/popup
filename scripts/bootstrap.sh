#!/usr/bin/env sh
#
# Install popup from the Pop Index. The index provides the release manifest,
# immutable artifact URL, and SHA-256 checksum; GitHub is never queried here.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/poplanguage/popup/master/scripts/bootstrap.sh | sh
#   POPUP_HOME=/opt/popup sh scripts/bootstrap.sh --no-modify-path

set -eu

INDEX_URL="${POP_INDEX_URL:-https://pop.squareweb.app}"
INDEX_URL=${INDEX_URL%/}
INSTALL_DIR="${POPUP_HOME:-$HOME/.popup}"
NO_MODIFY_PATH=0
TEMP_DIR=""

info() { printf '%s\n' "info: $*"; }
die() { printf '%s\n' "error: $*" >&2; exit 1; }

cleanup() {
  [ -z "${TEMP_DIR:-}" ] || rm -rf "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

for argument in "$@"; do
  case "$argument" in
    --no-modify-path) NO_MODIFY_PATH=1 ;;
    *) die "unknown argument: $argument" ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || die "$1 is required"; }

detect_target() {
  raw_os=$(uname -s 2>/dev/null || true)
  raw_arch=$(uname -m 2>/dev/null || true)
  case "$raw_arch" in
    x86_64|amd64) arch=x86_64 ;;
    aarch64|arm64) arch=aarch64 ;;
    *) die "unsupported architecture: $raw_arch" ;;
  esac
  case "$raw_os" in
    Linux) target="${arch}-unknown-linux-gnu" ;;
    Darwin) target="${arch}-apple-darwin" ;;
    *) die "unsupported operating system: $raw_os (use scripts/bootstrap.ps1 on Windows)" ;;
  esac
}

read_manifest_asset() {
  manifest=$(curl -fsSL "$INDEX_URL/v1/releases/latest/manifest?product=popup") || die "could not fetch Popup release manifest from $INDEX_URL"
  # Index manifests are JSON. Splitting object records lets this remain usable
  # on minimal POSIX systems without adding a jq/Python bootstrap dependency.
  record=$(printf '%s' "$manifest" | tr -d '\r\n\t ' | tr '{' '\n' | grep "\"name\":\"popup-${target}.zip\"" | head -n 1 || true)
  [ -n "$record" ] || die "no popup archive for $target is published by the Pop Index"
  artifact_url=$(printf '%s' "$record" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
  expected_sha=$(printf '%s' "$record" | sed -n 's/.*"sha256":"\([0-9A-Fa-f][0-9A-Fa-f]*\)".*/\1/p')
  [ -n "$artifact_url" ] || die "published popup artifact has no URL"
  printf '%s' "$expected_sha" | grep -Eq '^[0-9A-Fa-f]{64}$' || die "published popup artifact has an invalid SHA-256"
}

verify_sha256() {
  file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    actual_sha=$(sha256sum "$file" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    actual_sha=$(shasum -a 256 "$file" | awk '{print $1}')
  else
    die "sha256sum or shasum is required to verify popup"
  fi
  [ "$actual_sha" = "$expected_sha" ] || die "SHA-256 verification failed for popup"
}

install_binary() {
  TEMP_DIR=$(mktemp -d) || die "could not create temporary directory"
  chmod 700 "$TEMP_DIR"
  archive="$TEMP_DIR/popup.zip"
  download_url=$artifact_url
  case "$download_url" in
    http://*|https://*) ;;
    /*) download_url="$INDEX_URL$download_url" ;;
    *) download_url="$INDEX_URL/$download_url" ;;
  esac

  info "downloading popup for $target"
  curl -fL --retry 3 -o "$archive" "$download_url" || die "popup download failed"
  verify_sha256 "$archive"
  unzip -q "$archive" -d "$TEMP_DIR/unpacked" || die "could not extract popup archive"
  source_binary="$TEMP_DIR/unpacked/popup-$target"
  [ -f "$source_binary" ] || die "archive did not contain popup-$target"
  mkdir -p "$INSTALL_DIR/bin"
  install -m 755 "$source_binary" "$INSTALL_DIR/bin/popup"
}

configure_path() {
  bin_dir="$INSTALL_DIR/bin"
  case ":${PATH:-}:" in *":$bin_dir:"*) return ;; esac
  [ "$NO_MODIFY_PATH" -eq 0 ] || {
    info "activate popup with: export POPUP_HOME='$INSTALL_DIR'; export PATH='$bin_dir':\"\$PATH\""
    return
  }

  shell_name=$(basename "${SHELL:-sh}")
  case "$shell_name" in
    fish)
      profile="$HOME/.config/fish/config.fish"
      line="set -gx POPUP_HOME '$INSTALL_DIR'\nfish_add_path '$bin_dir'"
      ;;
    zsh)
      profile="$HOME/.zshrc"
      line="export POPUP_HOME='$INSTALL_DIR'\nexport PATH='$bin_dir':\"\$PATH\""
      ;;
    bash)
      profile="$HOME/.bashrc"
      line="export POPUP_HOME='$INSTALL_DIR'\nexport PATH='$bin_dir':\"\$PATH\""
      ;;
    *)
      profile="$HOME/.profile"
      line="export POPUP_HOME='$INSTALL_DIR'\nexport PATH='$bin_dir':\"\$PATH\""
      ;;
  esac
  mkdir -p "$(dirname "$profile")"
  if [ -f "$profile" ] && grep -F "$bin_dir" "$profile" >/dev/null 2>&1; then
    return
  fi
  {
    printf '\n# popup\n'
    printf '%b\n' "$line"
  } >> "$profile"
  info "added popup to $profile; restart your shell or source it to use popup"
}

main() {
  need curl
  need unzip
  need sed
  need grep
  detect_target
  read_manifest_asset
  install_binary
  configure_path
  info "installed popup to $INSTALL_DIR/bin/popup"
}

main
