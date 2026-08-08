#!/usr/bin/env bash
# installer for remote-zed-opener
set -euo pipefail

REPO="yigitkonur/remote-zed-opener"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/zed"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

echo "installing remote-zed-opener..."

mkdir -p "$INSTALL_DIR"

if [[ -f "./zed" ]]; then
  cp ./zed "$INSTALL_DIR/zed"
else
  curl -fsSL "$RAW_URL" -o "$INSTALL_DIR/zed"
fi

chmod +x "$INSTALL_DIR/zed"

echo "installed zed to $INSTALL_DIR/zed"

# check path
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo ""
    echo "warning: $INSTALL_DIR is not in your PATH!"
    echo "add this to your ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

echo ""
if [[ -t 0 ]]; then
  "$INSTALL_DIR/zed" --setup
else
  echo "installation complete! run 'zed --setup' to configure your ssh hosts."
fi
