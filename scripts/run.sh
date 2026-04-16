#!/usr/bin/env bash
# Triggers the PR Reviewer on a given PR. Requires the reviewer's profile ID
# (printed by setup.sh) and a PR URL.

set -euo pipefail

: "${ACP_API_KEY:?}"
: "${REVIEWER_PROFILE_ID:?Set REVIEWER_PROFILE_ID to the id returned by setup.sh}"
PR_URL="${1:?Usage: run.sh <github-pr-url>}"
BASE_URL="${ACP_BASE_URL:-https://api.agenticcontrolplane.com}"

curl -sf -X POST "$BASE_URL/api/v1/agents/$REVIEWER_PROFILE_ID/run" \
  -H "Authorization: Bearer $ACP_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"goal\": \"Review this PR: $PR_URL. Delegate security scan and tests, then post a summary comment.\"}" \
  | python3 -m json.tool
