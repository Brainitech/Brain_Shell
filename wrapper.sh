#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Brain_Shell — global launcher wrapper
#  Installed at /usr/local/bin/brain-shell
# ═══════════════════════════════════════════════════════════════════════════════

INSTALL_DIR="${BRAIN_SHELL_DIR:-$HOME/.local/src/Brain_Shell}"

# Ensure ~/.local/bin is in PATH (Quickshell may be installed there)
case ":$PATH:" in
    *:"$HOME/.local/bin":*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Ensure QML import paths match (Nix / user-installed Qt modules)
case ":$QML2_IMPORT_PATH:" in
    *:"$HOME/.local/lib/qml":*) ;;
    *) export QML2_IMPORT_PATH="$HOME/.local/lib/qml:$QML2_IMPORT_PATH" ;;
esac
export QML_IMPORT_PATH="$QML2_IMPORT_PATH"

# Delegate to the real CLI
exec "${INSTALL_DIR}/cli.sh" "$@"
