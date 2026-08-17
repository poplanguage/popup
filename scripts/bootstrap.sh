#!/usr/bin/env sh
#
# Install popup from its GitHub Release. Pop toolchains installed by popup use
# Pop Index; the manager itself remains independently bootstrappable.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/poplanguage/popup/master/scripts/bootstrap.sh | sh
#   POPUP_HOME=/opt/popup sh scripts/bootstrap.sh --no-modify-path

set -eu

GITHUB_API="https://api.github.com"
REPOSITORY="poplanguage/popup"
POPUP_VERSION="${POPUP_VERSION:-}"
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

github_get() {
  curl -fsSL -H "Accept: application/vnd.github+json" "$1"
}

read_release_assets() {
  if [ -n "$POPUP_VERSION" ]; then
    release_url="$GITHUB_API/repos/$REPOSITORY/releases/tags/$POPUP_VERSION"
  else
    # This includes the newest prerelease, unlike GitHub's /releases/latest.
    release_url="$GITHUB_API/repos/$REPOSITORY/releases?per_page=1"
  fi
  release=$(github_get "$release_url") || die "could not fetch Popup release metadata from GitHub"
  compact=$(printf '%s' "$release" | tr -d '\r\n\t ')
  record=$(printf '%s' "$compact" | tr '{' '\n' | grep "\"name\":\"popup-${target}.zip\"" | head -n 1 || true)
  checksum_record=$(printf '%s' "$compact" | tr '{' '\n' | grep "\"name\":\"popup-${target}.zip.sha256\"" | head -n 1 || true)
  [ -n "$record" ] || die "no popup archive for $target is published on GitHub"
  [ -n "$checksum_record" ] || die "no SHA-256 sidecar for popup-$target.zip is published on GitHub"
  # Asset API URLs occur before GitHub's nested uploader object, so they can
  # be parsed safely on minimal systems without a JSON runtime.
  artifact_url=$(printf '%s' "$record" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
  checksum_url=$(printf '%s' "$checksum_record" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
  [ -n "$artifact_url" ] || die "published popup archive has no download URL"
  [ -n "$checksum_url" ] || die "published popup checksum has no download URL"
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
  checksum="$TEMP_DIR/popup.zip.sha256"

  info "downloading popup for $target"
  curl -fL --retry 3 -H "Accept: application/octet-stream" -o "$archive" "$artifact_url" || die "popup download failed"
  curl -fL --retry 3 -H "Accept: application/octet-stream" -o "$checksum" "$checksum_url" || die "popup checksum download failed"
  expected_sha=$(awk '{print $1}' "$checksum")
  checksum_name=$(awk '{print $2}' "$checksum" | sed 's/^\*//;s|.*/||')
  [ "$checksum_name" = "popup-$target.zip" ] || die "invalid SHA-256 sidecar for popup-$target.zip"
  printf '%s' "$expected_sha" | grep -Eq '^[0-9A-Fa-f]{64}$' || die "invalid SHA-256 sidecar for popup-$target.zip"
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
  read_release_assets
  install_binary
  configure_path
  info "installed popup to $INSTALL_DIR/bin/popup"
}

main
