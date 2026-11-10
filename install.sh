#!/usr/bin/env bash
# installer for remote-zed-opener
set -euo pipefail

# the zed shim from the same release as this installer
VERSION="v1.0.0"
ZED_URL="https://github.com/yigitkonur/remote-zed-opener/releases/download/${VERSION}/zed"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/zed"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/remote-zed-opener/config"

echo "installing remote-zed-opener ${VERSION}..."
mkdir -p "$INSTALL_DIR"

# never replace someone else's zed, e.g. the zed editor's own linux cli (or a
# dangling link to it)
if [[ -e $TARGET || -L $TARGET ]] && ! grep -q remote-zed-opener "$TARGET" 2> /dev/null; then
  echo "error: $TARGET exists and is not remote-zed-opener (the zed editor's own cli?)." >&2
  echo "remove it, or install elsewhere: INSTALL_DIR=/some/dir bash install.sh" >&2
  exit 1
fi

# a checkout installs its own copy; curl | bash downloads. write a temp file and
# rename it, so an existing file or symlink is replaced rather than written through
tmp=$(mktemp "$INSTALL_DIR/.zed.XXXXXX")
trap 'rm -f "$tmp"' EXIT
src="$(dirname -- "${BASH_SOURCE[0]:-}")/zed"
if [[ -n ${BASH_SOURCE[0]:-} && -f $src ]] && grep -q remote-zed-opener "$src"; then
  cp "$src" "$tmp"
else
  curl -fsSL "$ZED_URL" -o "$tmp"
  # a captive portal or proxy page can come back as 200; never install that
  if ! grep -q remote-zed-opener "$tmp"; then
    echo "error: $ZED_URL did not return remote-zed-opener; nothing was changed." >&2
    exit 1
  fi
fi
chmod 755 "$tmp"
mv -f "$tmp" "$TARGET"
echo "installed zed to $TARGET"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo ""
    echo "warning: $INSTALL_DIR is not in your PATH. add this to your ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac

echo ""
if [[ -f $CONFIG_FILE ]]; then
  echo "keeping your config in $CONFIG_FILE (run 'zed --setup' to change it)."
elif [[ -t 0 ]]; then
  "$TARGET" --setup
elif { : < /dev/tty; } 2> /dev/null; then
  # curl | bash: stdin is the script, so ask on the terminal
  "$TARGET" --setup < /dev/tty
else
  echo "no terminal: run 'zed --setup', or write $CONFIG_FILE with MAC_HOST, REMOTE_HOST and MAC_ZED_BIN."
fi
