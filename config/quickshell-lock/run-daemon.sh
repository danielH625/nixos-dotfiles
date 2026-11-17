#!/usr/bin/env bash
set -euo pipefail
config_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
: "${XDG_RUNTIME_DIR:?Run this inside your graphical session}"
exec 9>"$XDG_RUNTIME_DIR/quickshell-lock.lock"
flock -n 9 || exit 0
wallpaper_state="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/current-wallpaper"
wallpaper_path=$(readlink -e -- "$wallpaper_state" || true)
# Pass a URL so spaces and punctuation in wallpaper filenames remain valid.
export QS_LOCK_WALLPAPER
QS_LOCK_WALLPAPER=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).as_uri() if sys.argv[1] else "")' "$wallpaper_path")
export QS_LOCK_START="${QS_LOCK_START:-0}"
exec quickshell --path "$config_dir/shell.qml"
