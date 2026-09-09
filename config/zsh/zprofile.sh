export ROOT_DIR="$HOME/ArchInstall"
source "$ROOT_DIR/config/zsh/exports.sh"

if uwsm check may-start; then
    exec uwsm start -D Hyprland Hyprland
fi
