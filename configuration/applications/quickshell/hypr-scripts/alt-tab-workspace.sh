#!/usr/bin/env bash

set -euo pipefail

direction="${1:?workspace direction required}"

qs -c ii ipc call search open
hyprctl dispatch workspace "$direction"
