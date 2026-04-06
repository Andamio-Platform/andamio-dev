---
name: troubleshoot
description: Debug Andamio API errors, CLI failures, and Cardano transaction rejections. Reads known gotchas and provides verified fixes.
license: MIT
metadata:
  author: Andamio
  version: 0.1.0
---

# Skill: Troubleshoot

## Description

Diagnoses errors from the Andamio API, CLI, and Cardano transactions. Reads the knowledge base of known gotchas and provides verified fixes. When a new error pattern is resolved, offers to capture it via `/compound`.

## Instructions

### Path Resolution

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read knowledge from `${CLAUDE_PLUGIN_DATA}/knowledge/` (user data), falling back to `${CLAUDE_PLUGIN_ROOT}/knowledge/` (seed data).
- **Clone/symlink context** (default): Read knowledge at `knowledge/` relative to project root.

### Pre-Execution Knowledge Check

1. Read `knowledge/gotchas.yaml` for known error patterns and verified fixes.
2. Read `knowledge/faq.yaml` for related questions that may provide context.
3. Proceed without knowledge files if they don't exist or are empty.

### Step 1: Collect Error Information

Ask the developer to paste the error output. If they describe the error verbally, ask for:

- The exact error message or HTTP status code
- The command or API endpoint they were using
- Whether this worked before or is a first attempt

### Step 2: Detect Error Source

Parse the error to determine the source:

**HTTP Status Codes → Gateway API issues:**

| Code | Common Cause | Quick Fix |
|------|-------------|-----------|
| 401 Unauthorized | Missing or expired credentials | Check API key and JWT. JWT expires ~24h. |
| 403 Forbidden | Insufficient permissions for this endpoint | Endpoint may require JWT (not just API key), or a specific role (owner, teacher, manager). |
| 404 Not Found | Resource doesn't exist | Verify the course_id, project_id, or module_code. Use `andamio course list --output json` to discover valid IDs. |
| 409 Conflict | Duplicate operation | Usually safe to ignore — idempotent retry hit an existing resource. |
| 429 Too Many Requests | Rate limit or quota exceeded | Check `andamio apikey usage`. Wait for window reset or upgrade tier. |
| 500 Internal Server Error | Server-side issue | Retry after a moment. If persistent, check service health: `GET /health`. |

**CLI Exit Codes → CLI issues:**

| Code | Meaning | Quick Fix |
|------|---------|-----------|
| 1 | Generic error | Check stderr output for details. Usually network or server issue. |
| 2 | Not found | Resource doesn't exist. Verify IDs with `andamio course list --output json`. |
| 3 | Auth required | No credentials or invalid credentials. Run `andamio auth status` and `andamio user status`. |

**Transaction Errors → Cardano issues:**

| Error | Common Cause | Quick Fix |
|-------|-------------|-----------|
| InsufficientFunds | Wallet doesn't have enough ADA | Use /cost-estimator to calculate required amount. Get test ADA from faucet on preprod. |
| ScriptFailure | Validator rejected the transaction | Check transaction parameters. Usually wrong role (not a teacher, not a manager). |
| UTxOContention | Another transaction consumed the same UTxO | Retry after a few seconds. Common during concurrent operations. |
| ExUnitsExceeded | Script execution exceeded budget | Contact Andamio team — this shouldn't happen with normal operations. |

### Step 3: Match Against Known Gotchas

Search `knowledge/gotchas.yaml` for matching error patterns. If a match is found:

```
Known issue: [gotcha title]

Root cause: [explanation]
Fix: [verified solution]

This fix has been verified [frequency] times.
```

### Step 4: Diagnose and Resolve

If no known gotcha matches, diagnose based on context:

1. **Auth issues**: Check both API key and JWT status
   ```bash
   andamio auth status   # API key
   andamio user status   # JWT + expiry
   ```

2. **Missing resources**: Verify the resource exists
   ```bash
   andamio course list --output json | jq '.data[].course_id'
   andamio project list --output json | jq '.data[].project_id'
   ```

3. **Content format issues**: Check for Tiptap JSON requirements
   - API endpoints expect Tiptap JSON for content fields
   - CLI handles conversion automatically — suggest using CLI instead of direct API

4. **Network issues**: Test connectivity
   ```bash
   andamio config show   # Check configured URL
   curl -s https://preprod.api.andamio.io/health | python3 -m json.tool
   ```

5. **Transaction issues**: Check wallet balance and transaction status
   ```bash
   andamio tx pending --output json
   andamio tx status <hash> --output json
   ```

### Step 5: Capture New Pattern

If you resolved a new error that isn't in the knowledge base, offer:

> "This was a new error pattern. Want me to capture it so future sessions can reference this fix? Run /compound to save it."

### Common Multi-Step Debugging Flows

**"I can import modules but lessons aren't created":**
1. Check if SLTs exist: `andamio course slts <id> <module> --output json`
2. If `data: []` → SLTs need to be created first (gotcha-005)
3. Create SLTs via API with `slt_index` omitted, then re-import

**"Transaction succeeded but data isn't showing up":**
1. Check tx status: `andamio tx status <hash> --output json`
2. If status is "pending" → wait for confirmation (usually < 60 seconds)
3. If status is "confirmed" → DB sync may be in progress, wait and refresh
4. If status is "failed" → chain confirmed but DB update failed. The gateway retries automatically (5 attempts, 30s backoff). Recovery: `andamio tx register --tx-hash <hash> --tx-type <type>` to re-register
5. The self-healing reconciler will catch up if there was a sync delay
6. See `andamio-cli/docs/TX-LIFECYCLE.md` for the full state machine and recovery procedures

**"Transaction confirmed but DB update failed" (tx run state: failed):**
1. The on-chain state is authoritative — your transaction IS confirmed on Cardano
2. The gateway will retry DB sync automatically (up to 5 times)
3. Check status: `andamio tx status <hash>`
4. If still "failed", re-register to retry: `andamio tx register --tx-hash <hash> --tx-type <type>`
5. For modules_manage failures: the DB likely couldn't match the module by SLT hash. Ensure you imported content first (which computes the hash) before minting on-chain

**"Everything works on preprod but fails on mainnet":**
1. Check environment: `andamio config show`
2. Verify mainnet API key (different from preprod key)
3. Verify mainnet wallet has real ADA
4. Verify the operation exists on mainnet (some features may be preprod-only)

### Guidelines

- Ask for the exact error output — don't guess from descriptions
- Check knowledge base first — known gotchas have verified fixes
- When the fix works, offer to capture it via /compound
- Don't recommend blind retries — diagnose the root cause
- For transaction errors, always suggest checking wallet balance first
