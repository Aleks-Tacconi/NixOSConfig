#!/usr/bin/env bash

set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
plugin_id="${HERDR_PLUGIN_ID:?HERDR_PLUGIN_ID is required}"
workspace_id="${HERDR_WORKSPACE_ID:?HERDR_WORKSPACE_ID is required}"
tab_id="${HERDR_TAB_ID:?HERDR_TAB_ID is required}"
pane_id="${HERDR_PANE_ID:?HERDR_PANE_ID is required}"
context="${HERDR_PLUGIN_CONTEXT_JSON:?HERDR_PLUGIN_CONTEXT_JSON is required}"
cwd="$(jq -er '.worktree.checkout_path // .workspace_cwd' <<<"$context")"
tabs="$("$herdr" tab list --workspace "$workspace_id")"

if ! jq -e '.result.tabs[]? | select((.label | ascii_downcase) == "agent")' <<<"$tabs" >/dev/null; then
  "$herdr" plugin pane open \
    --plugin "$plugin_id" \
    --entrypoint agent \
    --placement tab \
    --workspace "$workspace_id" \
    --cwd "$cwd" \
    --no-focus >/dev/null
fi

if ! jq -e '.result.tabs[]? | select((.label | ascii_downcase) == "editor")' <<<"$tabs" >/dev/null; then
  "$herdr" tab rename "$tab_id" Editor >/dev/null
  "$herdr" pane rename "$pane_id" Editor >/dev/null
  "$herdr" pane run "$pane_id" "exec nvim ." >/dev/null
fi
