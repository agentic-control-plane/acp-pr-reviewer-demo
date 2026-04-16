# ACP PR Reviewer — Agent-to-Agent Governance Demo

A three-agent pull-request reviewer that shows how [Agentic Control Plane](https://agenticcontrolplane.com) governs delegation between agents:

- **Scope narrows** at every hop (the scanner can't post, the test runner can't read secrets).
- **Budget propagates** and can only shrink (runaway bills stop at the first over-budget sub-call).
- **The human at the root is preserved** — every audit log entry traces back to the person who opened the PR.

This is a demo of [A2A governance](https://agenticcontrolplane.com/agent-to-agent), not a real CI bot. The two tools `secrets.scan` and `sast.run` are illustrative — wire them to your actual scanner (Trufflehog, Semgrep, etc.) via a custom connector.

## The chain

```
Alice (human)
 └─ PR Reviewer            scopes: github.pr.read, github.pr.comment   | budget $5.00
     ├─ Security Scanner   scopes: github.pr.read (intersected)         | budget $1.00
     │                     tools: secrets.scan, sast.run
     │                     canDelegate: false
     │
     └─ Test Runner        scopes: github.pr.read (intersected)         | budget $0.50
                           tools: tests.run
                           canDelegate: false
```

Things ACP enforces (verify in the dashboard activity log):

| Attempted                                  | ACP response                                           |
|--------------------------------------------|--------------------------------------------------------|
| Scanner tries `github.pr.comment`          | `-32004 Tool not permitted in delegation chain`        |
| Test runner tries to spawn a sub-agent     | `agents.invoke` tool is not in its effective set       |
| Scanner burns $1.20 of a $1.00 budget      | Next call blocked with `BUDGET`; parent continues      |
| PR description contains `169.254.169.254`  | Immutable rule fires at Layer 0a — blocked at any depth |
| Reviewer tries to delegate to itself       | `-32003 CYCLE`                                          |

Every one of those events shows up in your audit log with the full `delegation.chain` provenance.

## Setup

```bash
# 1. Get a gsk_ API key from the ACP dashboard (API Keys page).
export ACP_API_KEY="gsk_yourslug_xxxxxxxxxxxx"

# 2. Create all three agents in your workspace.
./scripts/setup.sh

# The output prints the ids. Grab the PR Reviewer's id and export it:
export REVIEWER_PROFILE_ID="prof_…"

# 3. Run it against any PR.
./scripts/run.sh https://github.com/your-org/your-repo/pull/42
```

Open the dashboard → Activity → filter by `agentRunId` for the run you just started. You'll see one row per tool call, each tagged with the full chain.

## What to look for in the audit log

Each log row exported as NDJSON carries:

```json
{
  "timestamp": "2026-04-15T14:23:09.412Z",
  "tool": "sast.run",
  "ok": true,
  "identity": { "sub": "auth0|alice" },
  "agent": { "profileId": "security-scanner", "runId": "run_abc123" },
  "delegation": {
    "originSub": "auth0|alice",
    "depth": 2,
    "chain": ["pr-reviewer", "security-scanner"],
    "runChain": ["run_parent", "run_abc123"],
    "parentProfileId": "pr-reviewer"
  }
}
```

Drop that NDJSON into Splunk HEC, Datadog Logs, or Sumo. Now your security team can answer *who did what, through which agents, and was it authorized* — from a single field on a single row.

## Next steps

- **Swap `secrets.scan` and `sast.run` for your real tools.** Register them as [custom connectors](https://agenticcontrolplane.com/docs) pointing at Trufflehog, Semgrep, SonarCloud, or your internal scanner.
- **Add a pre-hook** on the reviewer that routes high-severity findings to a human approver before the summary comment is posted.
- **Try other framework front-ends.** The same chain works from CrewAI, LangGraph, or the Anthropic Agent SDK — every framework-level delegation flows through the same ACP governance stack.

---

Questions or issues → [agenticcontrolplane.com/community](https://agenticcontrolplane.com/community)
