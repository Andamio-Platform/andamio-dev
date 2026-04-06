# Build on Andamio — Student Learning Targets

**Total: 31 SLTs across 7 modules.** *(Updated 2026-04-05: M200.1 and M200.2 merged into a single "Mint your access token" SLT.)*

Each module's SLT list is the input for its `slt_hash` when the course is
published. SLT wording is locked at this level of refinement — assessment
methods, parenthetical detail, and content specifics live in the lesson and
assignment content, not in the SLT.

---

## Module 100 — Foundations

*Mental model + working toolchain. Beachball-level entry points so learners build momentum before M200.*

1. I can explain Andamio's contribution-centered learning model.
2. I can install and configure the Andamio CLI (including API key setup).
3. I can fund a preprod wallet from the Cardano testnet faucet.
4. I can distinguish Learning Mode from Ops Mode in this plugin.

---

## Module 200 — Identity

*Self-sovereign on-chain identity. First real on-chain action happens here.*

1. I can mint an Andamio access token on preprod.
2. I can distinguish the `X-API-Key` auth method from the User JWT.
3. I can log in headlessly with a `.skey` file and receive a User JWT.
4. I can verify an Attestation JWT offline.

---

## Module 300 — Reading Andamio

*Pure read operations against the gateway API. No writes.*

1. I can interpret the `source` field on Andamio course and project responses.
2. I can navigate the Andamio gateway OpenAPI spec to find the right endpoint for a task.
3. I can query a user's Andamio credentials and interpret the response.
4. I can map each Andamio `tx_type` to its build endpoint.

---

## Module 400 — The Transaction State Machine

*The pattern behind every Andamio write operation. First low-stakes TX happens here.*

1. I can describe each step of the Andamio TX state machine.
2. I can explain why `updated` is the only safe TX status for refetching data.
3. I can execute an Andamio transaction through its full state machine.
4. I can diagnose and respond to Andamio TX failures.
5. I can explain which commitment states revert on TX expiry.

---

## Module 500 — Courses End-to-End

*Full course lifecycle. Create → publish module → enroll → assess → credential.*

1. I can explain how Andamio courses are structured.
2. I can compute an `slt_hash` for a course module.
3. I can publish a course module on-chain.
4. I can explain the course assignment commitment lifecycle.
5. I can run a full course lifecycle on Andamio.

---

## Module 600 — Projects End-to-End

*Full project lifecycle. Treasury → task → commit → assess → reward claim.*

1. I can explain how Andamio projects differ from courses.
2. I can compute a `task_hash` for a project task.
3. I can explain the project task commitment lifecycle.
4. I can run a full project lifecycle on Andamio.

---

## Module 700 — Build Something Real

*Capstone. Move from demo scripts to a real integration.*

1. I can choose the right Andamio integration strategy for a use case.
2. I can estimate the ADA cost of an Andamio user flow.
3. I can handle Andamio TX failure modes gracefully in code.
4. I can ship a minimal working Andamio integration.
5. I can critique the Andamio developer experience after building on it.
