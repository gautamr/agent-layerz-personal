#!/usr/bin/env bash
# Notification hook: pushes the message to your phone through ntfy when an agent needs you.
# Opt-in: does nothing unless NTFY_TOPIC is set (a long, unguessable name). NTFY_SERVER defaults
# to https://ntfy.sh; anyone who knows a public topic's name can read it, so self-host for
# anything sensitive. Never fails the session.
[ -n "${NTFY_TOPIC:-}" ] || exit 0
command -v curl >/dev/null 2>&1 || exit 0
msg=$(jq -r '.message // "An agent needs your attention"' 2>/dev/null || echo "An agent needs your attention")
project=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
curl -s -m 5 -H "Title: $project" -d "$msg" "${NTFY_SERVER:-https://ntfy.sh}/$NTFY_TOPIC" >/dev/null 2>&1 || true
exit 0
