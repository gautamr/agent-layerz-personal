#!/usr/bin/env bash
# SessionStart hook: a short brief so a session does not re-read the repository to orient
# itself. Prints at most about 20 lines. Uses the local board, or the hub's through BACKLOG_CWD.
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"; cd "$root" 2>/dev/null || exit 0
echo "=== Session brief: $(basename "$root") on $(git branch --show-current 2>/dev/null || echo '?') ==="
git log --oneline -3 2>/dev/null | sed 's/^/  /'
board="${BACKLOG_CWD:-$root}"
if command -v backlog >/dev/null 2>&1 && [ -d "$board/backlog" ]; then
  for s in "In Progress" "In Review"; do
    out=$(BACKLOG_CWD="$board" backlog task list --status "$s" --plain 2>/dev/null | grep -E '^\s+\S' | head -5)
    [ -n "$out" ] && { echo "$s:"; echo "$out"; }
  done
  owner=$(BACKLOG_CWD="$board" backlog task list --labels owner:human --exclude-status Done --plain 2>/dev/null | grep -cE '^\s+\S')
  echo "Waiting for the owner (owner:human): ${owner:-0}. Follow the delivery-protocol skill."
fi
exit 0
