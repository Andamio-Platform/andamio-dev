# Ship a minimal working Andamio integration

## Before we start

This is the capstone build. You'll go from zero to a working Andamio integration that does at least one meaningful thing — mint an access token, enroll in a course, submit evidence, or query credentials. The integration strategy from M700.1 determines your path; this lesson covers all three.

## Path A: Fork the template

The fastest path to a full web application. About nine minutes from `git clone` to a minted access token.

### Setup

```bash
git clone https://github.com/Andamio-Platform/andamio-app-template.git my-app
cd my-app
npm install
cp .env.example .env
```

Edit `.env` with your API key and preprod base URL:

```
NEXT_PUBLIC_ANDAMIO_API_URL=https://preprod.api.andamio.io
NEXT_PUBLIC_API_KEY=ak_your_key_here
```

### Run

```bash
npm run dev
```

Open `http://localhost:3000`. Connect your wallet (Nami, Eternl, or social login). Click "Mint Access Token" and sign the transaction. Wait for `updated`. You have a working Andamio-integrated app with wallet-connected identity.

### Your first code change

The template ships with semantic colors in `src/styles/globals.css`. Change the primary color:

```css
:root {
  --primary: oklch(0.669 0.199 38.581);   /* your brand color */
}
```

Hot reload. Entire app rebranded.

### Your first Andamio code change

The template includes a dashboard that queries courses. Modify `src/app/(app)/dashboard/page.tsx` to display credentials:

```typescript
import { useAndamioFetch } from "~/hooks/api/use-andamio-fetch";

export default function DashboardPage() {
  const { data: credentials } = useAndamioFetch({
    endpoint: "/v2/course/student/credentials/list",
    method: "POST",
    authenticated: true,
  });

  return (
    <div>
      <h1>My Credentials</h1>
      {credentials?.data?.map((cred: any) => (
        <div key={cred.course_id}>
          {cred.course_title} — {cred.claimed_credentials.length} earned
        </div>
      ))}
    </div>
  );
}
```

Types are auto-generated from the OpenAPI spec. The `useAndamioFetch` hook handles authentication headers and error states.

## Path B: Direct API integration

For existing applications. Any language, any framework.

### The minimum viable integration

Three API calls make a complete read integration:

```bash
# 1. Authenticate (get JWT)
andamio user login --skey ./payment.skey --alias my-alias --address $(cat payment.addr)

# 2. Query credentials
curl -X POST https://preprod.api.andamio.io/v2/course/student/credentials/list \
  -H "Authorization: Bearer $JWT" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json"

# 3. Display the result
```

In Python, Ruby, Go, or any language with an HTTP client, these are standard REST calls. No Cardano-specific libraries needed for read operations.

For write operations, you need transaction signing. Two options:
- **Delegate to the CLI:** call `andamio tx run` as a subprocess. The CLI handles build, sign, submit, register, and polling.
- **Implement the five steps:** build via API, sign with a Cardano library (Lucid, Mesh, PyCardano, cardano-cli), submit, register, poll. More control, more code.

### The scaffold

At minimum, a direct API integration needs:

| Component | What it does |
|-----------|-------------|
| Auth module | Manages API key and JWT. Refreshes JWT before expiry. |
| API client | Wraps fetch/requests with auth headers and error handling. |
| TX runner (for writes) | Implements the five-step state machine or delegates to CLI. |
| Status poller | Polls `tx status` until terminal state. Handles the five failure modes from M700.3. |

## Path C: CLI-first

For scripts, CI/CD, and automation. The examples you've already run are this path.

### The minimum viable script

```bash
#!/bin/bash
set -euo pipefail

# Query credentials for the authenticated user
andamio course student credentials list --output json \
  | python3 -c "
import json, sys
creds = json.load(sys.stdin)['data']
for c in creds:
    earned = len(c.get('claimed_credentials', []))
    print(f\"{c['course_title']}: {earned} credentials earned\")
"
```

The CLI's `--output json` flag makes every command composable. Pipe to `jq`, `python3`, or any JSON processor.

### From script to automation

```bash
# CI/CD: auto-publish a module when a course repo is tagged
andamio course create-module "$COURSE_ID" \
  --code "$MODULE_CODE" \
  --title "$MODULE_TITLE" \
  --slt "$(cat slts.txt | head -1)" \
  --approve

andamio course teacher update-module-status \
  --course-id "$COURSE_ID" \
  --module-code "$MODULE_CODE" \
  --status PENDING_TX

andamio tx run /v2/tx/course/teacher/modules/manage \
  --body-file modules.json \
  --skey "$SKEY_PATH" \
  --tx-type modules_manage \
  --instance-id "$COURSE_ID"
```

This is the M500.3 publishing flow, automated. The same pattern applies to any Andamio operation.

## What "minimal" means

The capstone isn't about building a production application. It's about proving you can connect the pieces:

1. **Authenticate** — API key, JWT, or both.
2. **Call the Andamio API** — at least one read or write.
3. **Handle the result** — display data, track a transaction, or process output.

A script that queries credentials and prints them is a valid integration. A forked template with one custom page is a valid integration. A Python function that creates a course module via the API is a valid integration. The bar is: it works, it talks to Andamio, and you wrote it.

## Your turn

Build a minimal Andamio integration using whichever strategy fits your situation. It should do at least one of:

- Query and display credentials for an alias
- Mint an access token
- Create a course or project
- Enroll in a course module
- Compute and verify an `slt_hash` or `task_hash`

When it works, note: (1) which strategy you chose, (2) what the integration does, and (3) a link to the code (repo, gist, or paste).

## Rubric

A valid submission is a working integration that talks to the Andamio API (preprod). Any strategy, any language, any scope. The code should demonstrate at least one API interaction (read or write) with proper authentication. The assignment will ask for the link and a brief description.

## What you just did

You shipped something. A working piece of code that talks to Andamio, authenticates, and does useful work. The strategy you chose — template, direct API, or CLI — is the one that fit your problem. The credential you'll earn for this module proves you can build on the protocol, not just read about it.
