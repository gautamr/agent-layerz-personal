#!/usr/bin/env bash
# PreToolUse hook for Edit and Write in a client hub: a hub session may read sibling
# repositories but never change them. Active only in a hub, recognised by the client layer it
# publishes at <repo>/layer/layer.yaml (agent-layerz hub layout). Everywhere else: allowed.
set -u
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -f "$root/layer/layer.yaml" ] || exit 0
command -v jq >/dev/null 2>&1 || { echo "Blocked: jq is not installed; the hub guard cannot check this edit." >&2; exit 2; }
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -n "$path" ] || exit 0
case "$path" in /*) abs="$path" ;; *) abs="$root/$path" ;; esac
case "$abs" in *..*) echo "Blocked: $path contains '..'." >&2; exit 2 ;; esac
case "$abs" in "$root"/*) exit 0 ;; esac
echo "Blocked: $path is outside the hub. Change a sibling repository in a session started inside it." >&2
exit 2
