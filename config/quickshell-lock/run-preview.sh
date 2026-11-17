#!/usr/bin/env bash
set -euo pipefail
config_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec quickshell --path "$config_dir/Preview.qml"
