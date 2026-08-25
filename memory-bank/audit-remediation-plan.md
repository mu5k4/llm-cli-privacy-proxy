# Audit Remediation Plan

## Source Artifacts
- `.audit/findings.json`
- `.audit/coverage.json`
- `.audit/scan-manifest.json`
- `.audit/report.md`

## Audit Snapshot
- Date reviewed: August 25, 2026
- Findings total: 11
- Severity mix: 2 high, 3 medium, 6 low
- Coverage status: partial
- Meaning: the static audit found clear remediation work, and some runtime validation is still required after code changes.

## Remediation Goals
1. Close the direct plaintext-leak paths first.
2. Prevent restored-secret injection into active protocol/tool fields.
3. Make the proxy deterministic, bounded, and testable under hostile inputs.
4. Remove install/config failure modes that can silently bypass the privacy boundary.
5. Finish the deferred runtime validation work once the implementation is pinned and testable.

## Priority 0: Confidentiality Breaks To Fix First

### 1. Replace the outbound request pass-through with an explicit allowlisted schema
Audit findings:
- High: Incomplete outbound request policy allows anonymization bypass

Problem:
- The proxy currently protects only selected input areas while still forwarding broader request structures, headers, query values, and content-bearing sibling fields upstream.
- That means secrets can bypass anonymization without any detector failure.

Work:
- Define the exact supported outbound Responses schema.
- Construct a new outbound request object instead of forwarding the caller payload wholesale.
- Classify every accepted field as one of: structural, content-bearing, or unsupported.
- Scan every supported content-bearing field.
- Strictly validate structural fields by path, type, enum, and length.
- Reject unknown fields, unsupported representations, and unsafe attachments fail-closed.
- Allowlist forwarded headers and query parameters instead of passing caller-controlled values through.
- Treat Authorization forwarding as an explicit documented trust boundary.
- Reject or tightly constrain media/URL-bearing fields until they have a bounded local inspection policy.

Required tests:
- Put fake secrets in every accepted top-level and nested supported field and assert the mock upstream never receives raw values.
- Add regression coverage for metadata, instructions, tool descriptions, schemas, defaults, enums, object keys, URLs, and nested content structures.

### 2. Add cross-slot detection for fragmented secrets
Audit findings:
- High: Splitting a secret across text slots bypasses both detectors

Problem:
- Sensitive values can cross adjacent text slots while each slot alone looks harmless.

Work:
- Build a canonical logical text stream for each semantic message.
- Preserve a reversible offset map from the canonical stream back to source slots.
- Detect across slot boundaries with no artificial separators.
- Redact every slot touched by a finding.
- Reject fragmented structures that cannot be reconstructed safely.
- Keep logical-message grouping narrow so unrelated fields are not merged.

Required tests:
- Split emails, tokens, phone numbers, card-like values, and URLs across every character boundary between adjacent slots.
- Cover nested content objects and list-based content separately.

### 3. Make restoration protocol-aware and text-only
Audit findings:
- Medium: Upstream output can inject restored secrets into protocol and tool fields

Problem:
- Placeholder restoration must not occur inside active fields such as tool arguments, identifiers, URLs, commands, or control structures.

Work:
- Parse the upstream SSE/Responses protocol structurally instead of doing broad text restoration.
- Restore placeholders only in explicitly approved passive human-visible assistant text fields.
- Never restore in tool names, tool arguments, status/control fields, URLs, commands, code, identifiers, encrypted blobs, or framing.
- Use per-request high-entropy placeholder handles.
- Detect placeholder collisions against inbound content.
- Make restoration a single non-recursive pass.
- If downstream tools need secrets, resolve them through a separate approved local secret path instead of response restoration.

Required tests:
- Return known placeholders in approved text fields and in blocked protocol/tool fields; verify restoration happens only in the approved text paths.
- Test placeholder tokens split across transport chunks.

## Priority 1: Silent Privacy-Boundary Failures

### 4. Fix local authentication and startup trust so OAuth credentials cannot be captured
Audit findings:
- Medium: Unauthenticated local proxy identity permits OAuth credential capture

Problem:
- A local impersonator on the configured port could capture credentials or intercept startup if the client trusts the endpoint too loosely.

Work:
- Add a real local authentication mechanism between client and proxy.
- Prefer a named pipe or similarly local-only authenticated channel if feasible; otherwise use a per-install secret protected with OS ACLs.
- Verify the local service identity before activating the client configuration.
- Only switch Codex/provider settings after authenticated startup succeeds.
- Roll back provider changes on install failure.
- Refuse startup if the expected local service identity is missing.

Required tests:
- Simulate a fake local listener and ensure install/wrapper refuse it.
- Verify missing or incorrect local auth is rejected before credentials are accepted.

### 5. Replace section-blind TOML rewriting with structural config edits
Audit findings:
- Medium: Section-blind TOML rewriting can leave Codex outside the privacy proxy

Problem:
- Install/uninstall can silently leave the client pointed at the wrong provider if config rewriting is not table-aware.

Work:
- Use a TOML-aware read/modify/write path.
- Update only the intended root/table keys.
- Preserve unrelated settings, comments where practical, and table-scoped values.
- Write atomically and reparse after writing.
- Verify the effective provider after install and uninstall.
- Fail loudly if the resulting config does not point at the privacy provider when expected.

Required tests:
- Run install/uninstall against configs with nested tables, duplicates, comments, profiles, and preexisting provider settings.
- Verify the doctor/status path fails if the active provider is not the expected one.

## Priority 2: Hardening, Correctness, And State Safety

### 6. Bound request size, scanner work, retained state, and disk growth
Audit findings:
- Low: Unbounded analysis and retained state enable proxy resource exhaustion

Work:
- Enforce request size, JSON depth, field count, slot count, chunk count, and aggregate text limits before expensive scanning.
- Add request concurrency limits and bounded worker queues.
- Add subprocess timeouts with child termination.
- Add session TTLs, explicit deletion, one-shot restoration where applicable, maximum retained bytes, and eviction.
- Bound persistent cache size and write behavior.
- Add container-level CPU, memory, PID, and disk protections where applicable.

Required tests:
- Verify oversize and over-depth payloads fail before detector allocation.
- Verify stalled analyzer work is terminated.

### 7. Pin privacy-critical dependencies immutably
Audit findings:
- Low: Mutable privacy-critical dependencies can execute while processing raw prompts

Work:
- Pin container images by digest.
- Lock Python dependencies with exact versions and hashes.
- Pin model artifacts/revisions immutably and verify checksums.
- Prefer controlled mirrors or approved sources.
- Restrict unnecessary analyzer egress.
- Run privacy-critical components with the least privileges practical.

Required tests:
- Fail CI or validation if any image/tag is mutable.
- Verify hashed dependency install rejects tampered artifacts.

### 8. Preserve the union of overlapping sensitive ranges
Audit findings:
- Low: Overlap resolution discards sensitive outer ranges instead of preserving their union

Work:
- Merge overlapping sensitive intervals by full covered character range.
- Choose labels/placeholders separately from replacement boundaries.
- Never drop sensitive outer characters just because an inner span won priority.

Required tests:
- Add synthetic nested and partial-overlap cases.
- Add real detector cases like cards inside URLs or identifiers inside larger PII spans.

### 9. Remove caller-selected restoration sessions or bind them strongly to ownership
Audit findings:
- Low: Caller-addressable sessions permit cross-client plaintext restoration

Work:
- Stop accepting arbitrary caller-chosen session IDs.
- Generate high-entropy server-side capabilities.
- Bind sessions to an authenticated local principal or equivalent ownership proof.
- Add TTL, quotas, one-shot restore, and delete-after-use.
- Prefer keeping restore mappings request-scoped inside `/responses` instead of exposing reusable standalone restoration in production.

Required tests:
- Verify one client cannot restore another client's session.
- Verify expiration and delete-after-restore behavior.

### 10. Fix chunk-boundary handling for long entities
Audit findings:
- Low: Fixed detector overlap can miss long entities at chunk boundaries

Work:
- Either define and enforce a supported maximum entity length with derived overlap, or implement span stitching/full rescans across chunk boundaries.
- Accept a detection only after the full entity visibility requirement is met.

Required tests:
- Boundary tests around every 4,000-character split using values below, equal to, and above the supported overlap.

### 11. Invalidate stale false-negative cache entries after security-relevant changes
Audit findings:
- Low: Detector cache preserves stale false negatives across security updates

Work:
- Include recognizer versions, config hash, model/artifact digests, thresholds, language, and app version in cache keys.
- Invalidate cache on mismatch.
- Add TTL/size limits.
- Avoid caching negative detections if safe invalidation cannot be guaranteed.

Required tests:
- Change recognizer/model/config inputs after an empty result and verify the text is rescanned.

## Execution Order

### Phase 1: Privacy-boundary redesign
- Item 1: outbound request allowlist/schema rebuild
- Item 2: cross-slot canonical scanning
- Item 3: protocol-aware restoration fence

Reason:
- These close the clearest direct plaintext disclosure paths.

### Phase 2: Installation and trust-path safety
- Item 4: local authentication/service identity
- Item 5: TOML-safe config management

Reason:
- These prevent silent bypass or credential theft during install/startup.

### Phase 3: Runtime hardening and state control
- Item 6: resource bounds and TTLs
- Item 9: session ownership and lifetime
- Item 11: cache invalidation

Reason:
- These tighten abuse resistance and state correctness after the main boundary is fixed.

### Phase 4: Detection correctness hardening
- Item 8: overlap-union preservation
- Item 10: long-entity boundary handling

Reason:
- These are lower-severity than the direct bypasses but still affect confidentiality correctness.

### Phase 5: Supply-chain hardening
- Item 7: immutable dependency and image pinning

Reason:
- Important, but most effective once the runtime and tests are stable enough to lock confidently.

## Deferred Runtime Validation Work
These came from `coverage.json` and should be scheduled after the first remediation passes land.

1. Long-entity overlap validation with the exact pinned analyzer versions.
2. Real detector overlap/co-occurrence validation for nested and partially overlapping spans.
3. Sanitized capture of actual supported request shapes emitted by the client.
4. Fake-placeholder downstream action tests under the real approval policy.
5. Inventory reconciliation for the 29-versus-31 file discrepancy.
6. Verification of the effective bind host in the deployed environment.

## Suggested Work Breakdown For we

### Workstream A: Request/response boundary redesign
- Redesign outbound schema handling
- Redesign placeholder restoration
- Add exhaustive request-shape and response-shape tests

### Workstream B: Detection pipeline correctness
- Implement cross-slot scanning
- Fix overlap-union logic
- Fix long-entity boundary behavior
- Add detector-focused regression fixtures

### Workstream C: Operational safety
- Add auth/identity checks for the local endpoint
- Bound request sizes, queues, sessions, and cache growth
- Fix config install/uninstall editing and verification

### Workstream D: Supply chain and reproducibility
- Lock dependency/image/model versions and hashes
- Add validation checks for mutable references

## Definition Of Done
- All 11 findings have a mapped code/config/test change.
- High-severity paths are blocked by regression tests.
- Medium-severity install/startup failures are fail-closed and verified by doctor/status checks.
- Low-severity state/correctness issues have automated regression coverage.
- Deferred runtime checks from `coverage.json` are either completed or explicitly tracked as remaining follow-up work.
