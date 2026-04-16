#!/usr/bin/env bash
# Posts the three agent profiles to your ACP workspace via the public API.
# Requires: ACP_API_KEY (gsk_…) and ACP_BASE_URL (default api.makeagents.run).

set -euo pipefail

: "${ACP_API_KEY:?ACP_API_KEY is required (e.g. gsk_myslug_xxxxxxxx). Get one from the dashboard: API Keys page.}"
BASE_URL="${ACP_BASE_URL:-https://api.agenticcontrolplane.com}"

HERE="$(cd "$(dirname "$0")/.." && pwd)"

post_agent() {
  local file="$1"
  local name
  name=$(python3 -c "import json,sys; print(json.load(open('$file'))['name'])")
  echo "→ Creating agent: $name"
  curl -sf -X POST "$BASE_URL/api/v1/agents" \
    -H "Authorization: Bearer $ACP_API_KEY" \
    -H "Content-Type: application/json" \
    -d @"$file" | python3 -m json.tool
  echo
}

post_agent "$HERE/agents/security-scanner.json"
post_agent "$HERE/agents/test-runner.json"
post_agent "$HERE/agents/pr-reviewer.json"

echo "Done. Open your dashboard → Agents to see all three."
