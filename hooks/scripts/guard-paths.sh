#!/usr/bin/env bash
# PreToolUse hook for Edit and Write. Refuses an edit by a role agent outside the paths its line
# in <repo>/ownership.conf allows. Format of ownership.conf, one role per line:
#   backend-engineer: src tests docs/standards
# No ownership.conf, no agent_type in the hook input (the main session), or a role without a
# line: the edit is allowed. Paths outside the repository are always refused for a listed role.
set -u
input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
conf="$root/ownership.conf"
[ -f "$conf" ] || exit 0
command -v jq >/dev/null 2>&1 || { echo "Blocked: jq is not installed; the role path guard cannot check this edit." >&2; exit 2; }
role=$(printf '%s' "$input" | jq -r '.agent_type // empty')
[ -n "$role" ] || exit 0
allowed=$(grep -E "^${role}:" "$conf" | head -n 1 | cut -d: -f2- | sed 's/^ *//')
[ -n "$allowed" ] || exit 0
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -n "$path" ] || exit 0
case "$path" in /*) abs="$path" ;; *) abs="$root/$path" ;; esac
case "$abs" in
  "$root"/*) rel="${abs#"$root"/}" ;;
  *) echo "Blocked: $path is outside this repository." >&2; exit 2 ;;
esac
case "$rel" in *..*) echo "Blocked: $path contains '..'." >&2; exit 2 ;; esac
for dir in $allowed; do
  dir="${dir%/}"
  case "$rel" in "$dir"|"$dir"/*) exit 0 ;; esac
done
echo "Blocked: $rel is outside the $role area ($allowed). Report the change to the lead instead." >&2
exit 2
