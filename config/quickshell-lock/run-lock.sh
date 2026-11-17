#!/usr/bin/env bash
set -euo pipefail
config_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ! -r /etc/pam.d/quickshell-lock ]]; then
    printf '%s\n' 'Missing /etc/pam.d/quickshell-lock. Apply the NixOS PAM configuration first.' >&2
    exit 1
fi
: "${XDG_RUNTIME_DIR:?Run this inside your graphical session}"
if command -v pidof >/dev/null && pidof hyprlock >/dev/null; then
    exit 0
fi
wallpaper_state="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/current-wallpaper"
wallpaper_path=$(readlink -e -- "$wallpaper_state" || true)
wallpaper_url=$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).as_uri() if sys.argv[1] else "")' "$wallpaper_path")
if quickshell ipc --path "$config_dir/shell.qml" call lock lock "$wallpaper_url" 2>/dev/null; then
    exit 0
fi
# Cold fallback: starting the background process also requests a lock.
QS_LOCK_START=1 nohup bash "$config_dir/run-daemon.sh" >"$XDG_RUNTIME_DIR/quickshell-lock.log" 2>&1 </dev/null &
for attempt in {1..100}; do
    if quickshell ipc --path "$config_dir/shell.qml" call lock lock "$wallpaper_url" 2>/dev/null; then
        exit 0
    fi
    sleep 0.05
done
printf '%s\n' "Lock failed to start. See $XDG_RUNTIME_DIR/quickshell-lock.log" >&2
exit 1
