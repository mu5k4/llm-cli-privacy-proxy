# Security Review: llm-cli-privacy-proxy-v0.1.0-20260824-154712

## Scope

Independent already-validated Standard static reviews covered the exact supplied non-Git scope '.'. The explicit artifact list contains 31 paths. Inventory reporting remains unresolved: the prior aggregate recorded a 29-versus-31 discrepancy, one newly assigned worker described 27 reviewed files while listing 31 paths, and the other reported all 31 current-state files. The newly assigned validated Standard result also lists the same 31 concrete package paths; the earlier inventory-count discrepancy remains unresolved and is deferred.

- Scan mode: deep_repository
- Target kind: directory_snapshot
- Target ID: target_sha256_cb86f5272d7fcadfd2d6d1436e2e29a54f96a4b331d7fc945d8f401ef5416491
- Snapshot digest: codex-security-snapshot/v1:sha256:dc64db08f6a732098ed064be1ebce018de6164fb868bbe96765a65bdb7bd6d7b
- Inventory strategy: repository
- Included paths: .
- Excluded paths: none
- Runtime or test status: Static source review only; application code, network services, external registries, production deployment, upstream behavior, and downstream CLI/tool execution were not exercised. The assigned worker likewise executed no application code and opened no network resources. Static source review only; repository application code and network paths were not executed. Static source review only. The application, containers, external analyzers, upstream APIs, and dependencies were not executed or fetched. Application code and dependencies were not executed; no network or external application was accessed.
- Artifacts reviewed: .env.example, .gitignore, analyzer-config.yaml, CHANGELOG.md, CONTRIBUTING.md, docker-compose.yml, Dockerfile.analyzer, README.md, recognizers.yaml, VERSION, docs/integrations/claude-code.md, docs/integrations/codex-cli.md, docs/teammate-handoff.md, privacy-cache/.gitkeep, privacy-service/app.py, privacy-service/Dockerfile, privacy-service/proxy.py, privacy-service/requirements.txt, scripts/bootstrap.ps1, scripts/codex-status.ps1, scripts/codex-with-privacy.ps1, scripts/common.ps1, scripts/demo-proof.ps1, scripts/doctor.ps1, scripts/install.ps1, scripts/package.ps1, scripts/regression.ps1, scripts/start.ps1, scripts/status.ps1, scripts/stop.ps1, scripts/uninstall.ps1, privacy-service/app.py and privacy-service/proxy.py, privacy-service dependency and container definitions, PowerShell lifecycle, installation, wrapper, regression, packaging, and uninstall scripts, docker-compose.yml, Dockerfile.analyzer, analyzer-config.yaml, recognizers.yaml, and environment defaults, README, integration guides, handoff documentation, changelog, contribution guidance, version marker, ignore rules, and cache placeholder
- Scan context: The requested anonymization-bypass focus and all supplied context were treated as untrusted analysis data; no userContext URL was opened or dereferenced. The exact user context requested anonymization-bypass discovery and was treated as untrusted data; no URLs were opened or dereferenced.

Limitations and exclusions:
- External dependency and model behavior was assessed only where repository source established the dataflow.
- Whether a downstream Codex tool call executes automatically depends on client policy outside this repository.
- No production deployment, external dependency implementation, live upstream behavior, or downstream CLI tool-execution policy was tested.
- The default deployment is loopback-only; findings that depend on widened binding or downstream execution state those prerequisites.
- Worker inventory counts conflict: one explicitly lists 29 reviewed files, while the other states that all 31 in-scope files were reviewed.
- The exact external detector rules needed to resolve the long-entity overlap question were not inspected.
- Detector/model runtime behavior and downstream client tool-approval behavior were not reproduced; findings that depend on them state those prerequisites and have reduced severity or confidence.
- No deployment claim beyond the source-defined default loopback binding and documented configurable bind override is made.
- No runtime reproduction, external dependency lookup, live Codex payload capture, or upstream schema fetch was performed.
- Downstream tool execution and approval behavior were treated as prerequisites where relevant.
- No SECURITY.md policy, scoped-source inventory, threat model, or knowledge base was supplied.
- Concrete overlap, long-entity, optional client-shape, and downstream-action behavior require the deferred runtime follow-ups listed in coverage.
- No runtime detector accuracy measurements, upstream service behavior, or downstream Codex tool-approval behavior were assumed.
- Dependency registries, container images, model artifacts, Git history, and deployment state were not inspected.
- Default loopback exposure was derived from repository configuration; operators can override the bind host.
- No live Codex request capture or runtime exploit reproduction was performed.
- External dependency artifacts and model contents were not resolved or executed.
- Findings with deployment or downstream-tool prerequisites state those prerequisites explicitly.
- No runtime reproduction was performed because the audit was source-only and offline.
- External image, package, and model contents were not fetched; mutable dependency references were reviewed as source configuration but no current third-party compromise was assumed.
- Severity reflects the default loopback deployment and documented Codex integration; widening PROXY_BIND_HOST can increase reachability.
- No live deployment, detector runtime, upstream call, or dependency fetch was performed.
- Runtime-specific client fields and tool-call round trips remain explicit prerequisites where noted.
- No SECURITY.md guidance, supplied threat model, scoped inventory file, or knowledge-base document was present.

### Scan Summary

| Field | Value |
| --- | --- |
| Reportable DSS findings | 11 |
| Report instances | 11 |
| Report severity mix | high: 2, medium: 3, low: 6 |
| Report confidence mix | high: 5, medium: 6 |
| Coverage | partial |
| Validation mode | Complete already-validated Standard scan results were semantically reduced without repository inspection, runtime reproduction, revalidation, or attack-path reruns. |

Canonical artifacts: `scan-manifest.json`, `findings.json`, and `coverage.json`. This report is a deterministic projection of those files.

## Threat Model

The local proxy is intended to keep raw PII, secrets, credentials, and workspace text on-host while forwarding only protected Responses traffic and restoring placeholders locally. Principal risks are incomplete outbound request coverage, representation and range-boundary detector evasion, context-blind restoration into model-selected fields, unauthenticated loopback service identity, caller-addressable plaintext sessions, unbounded local work/state, stale cached privacy decisions, section-confused provider configuration, and mutable privacy-critical dependencies. A loopback privacy proxy sits between local LLM CLI clients and a remote Responses upstream. Raw input is analyzed by Presidio and Nosey Parker, replaced with session-scoped GP_\* tokens, sent remotely, and restored on the response stream. The upstream, untrusted local processes, request-shaping integrations, and mutable build dependencies are relevant attackers.

### Assets

- Raw prompt, instruction, tool, metadata, and workspace text containing secrets or PII
- Locally retained token-to-original mappings
- Codex authorization credentials forwarded to the configured upstream
- Integrity of downstream response fields and local tool-call arguments
- Availability of the proxy, analyzer, process memory, and persistent cache volume
- Raw prompt PII, credentials, repository paths, and workspace content
- In-memory token-to-original session mappings
- Availability of the local privacy proxy and analyzer
- Integrity of locally restored Responses protocol data
- Codex OAuth authorization credential
- Secrets, credentials, PII, internal URLs, source content, and workspace context in LLM requests
- Local token-to-plaintext restoration mappings
- Caller OAuth authorization headers
- Privacy proxy, detector, host disk, CPU, memory, and process availability
- Raw prompts, repository text, PII, internal paths, and credentials before upstream transmission
- Codex/OpenAI OAuth Authorization headers
- In-memory placeholder-to-plaintext mappings and service availability
- Integrity of restored response fields, tool arguments, and Codex provider configuration
- Authenticity of the loopback privacy service receiving OAuth-bearing requests
- Correct effective Codex model-provider configuration
- Freshness and integrity of cached detector decisions
- Raw PII, credentials, private paths, workspace context, and other prompt content intended to remain local
- Codex OAuth authorization headers forwarded to the configured upstream
- Local placeholder-to-original mappings and derived detector cache metadata
- Integrity of machine-actionable Responses events and downstream tool arguments
- Availability of the privacy proxy, analyzer, container resources, and host-mounted cache
- Prompt and workspace text before anonymization
- PII, credentials, internal URLs, identifiers, and repository data
- Codex/OpenAI authorization headers
- In-memory placeholder-to-original mappings
- Availability of the proxy, detector processes, memory, and host-mounted cache
- Integrity of restored responses and downstream tool arguments
- Plaintext prompts, workspace content, PII, credentials, private identifiers, and internal URLs
- Codex/OpenAI OAuth bearer credentials forwarded through the configured provider
- Reversible per-request and manual-session token mappings
- Availability of the local proxy, analyzer, cache storage, and client workflow
- Integrity of Codex provider configuration and downstream tool-call semantics
- Raw prompts, repository text, instructions, PII, credentials, signed URLs, and workspace metadata
- Codex OAuth Authorization header and configured upstream identity
- In-memory token-to-original mappings
- Privacy service, analyzer, cache, and host availability
- Codex configuration and installation integrity

### Trust Boundaries

- Caller-controlled Responses JSON crossing into the local FastAPI proxy
- Raw text crossing from the proxy to local Presidio, GLiNER, and Nosey Parker detectors
- Anonymized request JSON and authorization headers crossing to remote UPSTREAM_BASE
- Untrusted upstream streamed bytes crossing through local placeholder restoration into the Codex client
- Unauthenticated loopback clients crossing into /protect, /restore, and detector work
- Caller or CLI to the local FastAPI proxy
- Privacy proxy to the local Presidio analyzer, which receives raw text
- Privacy proxy to the external UPSTREAM_BASE, which must receive only protected content except deliberate protocol/authentication data
- External upstream response stream back to the local CLI and its tools
- Container build to mutable public image and Python package registries
- Local CLI or other HTTP caller to the loopback FastAPI proxy
- Privacy proxy to local Presidio/GLiNER and Nosey Parker detectors
- Privacy proxy to the configured remote LLM upstream
- Upstream streamed protocol events to the local agentic client
- Privacy-service container to the host bind-mounted cache directory
- Local CLI or caller to loopback FastAPI service
- Privacy service to Presidio HTTP analyzer and Nosey Parker subprocess
- Privacy service to external upstream LLM endpoint
- Untrusted upstream stream through restoration into the local client and possible tool executor
- Downloaded build inputs and local configuration scripts into privacy-critical runtime code and Codex config
- Codex provider configuration and readiness scripts to the loopback service identity
- Persisted detector decisions across analyzer, model, configuration, and application updates
- Local CLI or HTTP caller to the FastAPI privacy service
- Privacy service to the Presidio analyzer container using raw text
- Privacy service to the configured external upstream using anonymized payloads and caller authorization
- Untrusted upstream SSE/JSON bytes to the local client and any downstream tool executor
- In-memory sensitive mappings and persistent cache to local processes and the host filesystem
- LLM client or local caller to the loopback FastAPI proxy
- Privacy service to the Presidio/GLiNER analyzer while plaintext is still present
- Privacy service to the remote UPSTREAM_BASE with forwarded authorization
- Untrusted upstream response bytes to the local client after placeholder restoration
- Container state to the host-mounted privacy-cache directory
- Installer package and environment configuration to the user's Codex configuration
- LLM CLI or direct HTTP caller to the loopback FastAPI service
- Structured Responses request data to detector slot extraction and replacement
- Privacy service to the Presidio analyzer and Nosey Parker subprocess
- Anonymized request and OAuth headers from the local proxy to the configured upstream
- Raw upstream streaming bytes through placeholder restoration to the downstream CLI
- Repository and environment configuration to Docker and the user's Codex provider configuration
- Local CLI to loopback FastAPI
- Privacy service to Presidio sidecar carrying raw text
- Privacy service to remote UPSTREAM_BASE carrying protected request and Authorization
- Remote stream to local restoration and downstream protocol
- External registries to local analyzer build
- Loopback services to other local processes

### Attacker Capabilities

- Control arbitrary structured JSON values supplied to POST /responses or the public protect/restore API
- Influence model output through untrusted prompt, document, tool, or plugin content
- Call the loopback service from another local process; remote reachability requires a nondefault widened bind
- Place sensitive data across protocol fields, excluded key names, or multiple text slots
- Supply structured JSON and arbitrary text to local proxy endpoints
- Shape sensitive content across multiple input strings or unsupported fields
- Supply any Authorization header value to reach local /responses analysis
- Control upstream response text if the model or provider is malicious or prompt-influenced
- Compromise or publish a malicious update to a mutable build dependency
- Control the structure, values, size, and nesting of a /responses JSON body and supply an arbitrary Authorization header value
- Reach the default loopback service from another local process; reach it remotely only if an operator widens PROXY_BIND_HOST
- Influence upstream model output through prompt injection or act as a compromised/malicious upstream that sees generated placeholders
- Choose a standalone /protect session identifier and call /restore when the identifier is known or induced to be reused
- Shape request JSON, nested content, segmentation, long inputs, and reusable standalone session identifiers
- Influence upstream model output through prompt injection or control a compromised upstream
- Run an untrusted same-host process able to reach or squat loopback ports
- Compromise a mutable registry or package artifact used during a build
- Bind the configured loopback port before the legitimate service when already executing locally
- Influence a valid preexisting TOML configuration containing table-scoped model_provider keys
- Repeat text previously cached under weaker detector state
- Choose arbitrary JSON structures and text at the public /protect or /responses parser boundary
- Split sensitive data across structured input fields or position it near detector chunk boundaries
- Influence upstream model output through prompt injection or act as a compromised upstream response producer
- Connect to loopback services as an unprivileged local process; connect remotely only when an operator widens the bind address
- Send arbitrary Authorization header values and many unique requests, but not alter trusted runtime environment variables under the default assumptions
- Influence repository, document, plugin, tool, or client content included in an authorized Responses request
- Choose JSON structure, text-slot boundaries, and media URL values at a public protocol boundary
- Influence model output through prompt injection and replay visible GP_\* placeholders
- Send requests from an untrusted local process; reach the service remotely only when bind configuration is broadened
- Sustain unique or oversized requests using any nonempty Authorization header before upstream validation
- For the supply-chain finding only, compromise a mutable image, package, or model distribution source
- Shape supported or extension JSON fields and split content across multiple input slots
- Supply repository-derived or client-generated content that may occupy prompt-bearing protocol fields
- Control upstream response bytes after observing placeholder tokens, including structured tool-call content
- Send HTTP requests to published loopback ports as a separate local process; reach them remotely only when the operator broadens the bind host
- Bind an otherwise free unprivileged loopback TCP port while the genuine proxy is stopped
- Remote upstream observes placeholders and controls response bytes
- Untrusted local process reaches default loopback ports
- Integration or untrusted content may influence request structure and segmentation
- Supply-chain attacker may replace mutable artifacts
- Operator may widen configurable bind host

### Security Objectives

- No caller-controlled sensitive request content reaches the upstream in plaintext
- Detection failures and unsupported request shapes fail closed
- Upstream-controlled output cannot choose unsafe locations where local originals are restored
- Plaintext mappings and detector caches have bounded size and lifetime
- Only a trusted HTTPS upstream receives Codex authorization credentials
- No sensitive outbound request content bypasses local detection and tokenization
- Structured boundaries do not reduce detector coverage
- Restoration inserts originals only into explicitly authorized response fields
- Untrusted requests cannot allocate unbounded compute, memory, disk, or retained session state
- Analyzer code that sees raw prompts is reproducibly pinned and integrity-verified
- No sensitive caller-controlled representation leaves the host without redaction or explicit rejection
- Placeholder restoration never turns untrusted upstream control data into local plaintext secrets
- Restoration mappings remain isolated, short-lived, and inaccessible across callers
- Malformed or large local requests cannot consume unbounded CPU, memory, process, or host-disk resources
- Detector failures fail closed before upstream transmission
- No raw sensitive request content reaches the upstream outside explicit documented exceptions
- Detection failures and unsupported protocol shapes fail closed
- Placeholders restore only into authorized non-executable display contexts
- OAuth credentials and session mappings remain bound to the intended local service and caller
- Untrusted work and persistent state remain bounded
- Privacy-critical dependencies and cached security decisions are version-bound and integrity verified
- Codex authenticates the intended local proxy before sending OAuth credentials or prompts
- Standalone session mappings are owner-bound, short-lived, and non-reusable across callers
- Detector cache entries are bound to every decision input and invalidated on security changes
- Installation verifies the effective root provider rather than a textual nested key
- No sensitive semantic request content reaches the upstream without inspection, redaction, or explicit rejection
- Restoration occurs only in approved display-only response fields and cannot materialize secrets in commands or tool arguments
- Detection coverage is invariant under supported structured representation and chunking
- Unauthenticated or invalid clients cannot trigger unbounded computation, subprocesses, memory, or persistent storage
- Sensitive mappings and derived metadata have bounded scope, lifetime, and access
- No sensitive caller-controlled content crosses to the upstream without scanning, anonymization, or explicit rejection
- Changing protocol representation must not bypass detection
- Only authentic placeholders may be restored, and never into unsafe response contexts
- Detection fails closed without enabling unbounded work or persistent state growth
- Authorization is forwarded only to the intended trusted upstream
- Components that see plaintext are integrity-pinned and minimally privileged
- No sensitive caller content reaches the upstream without protection or an explicit fail-closed rejection
- Representation changes, field placement, and slot boundaries do not bypass detection
- Upstream output cannot use placeholder restoration as authority to materialize secrets in active downstream fields
- OAuth credentials are delivered only to an authenticated intended endpoint
- Untrusted requests cannot consume unbounded CPU, subprocess, memory, disk, or retained-session resources
- No raw sensitive text crosses upstream before classification
- Detector failures and unclassified fields fail closed
- Restoration never inserts originals into identifiers, URLs, or actionable fields
- Sessions, caches, requests, subprocesses, and containers are bounded
- Only immutable reviewed analyzer code processes raw prompts
- Authorization is sent only to the intended upstream

### Assumptions

- The shipped Compose defaults bind published services to 127.0.0.1.
- UPSTREAM_BASE remains the shipped HTTPS Codex backend unless deliberately reconfigured by the operator.
- No repository SECURITY.md or authoritative knowledge base was supplied or resolved.
- The review covers the current unversioned source state only.
- The documented default binds proxy and analyzer ports to 127.0.0.1.
- PRESIDIO_URL and UPSTREAM_BASE are trusted administrator configuration; no request-controlled destination path was found.
- A valid user-supplied threat model was not provided, so this model is source-derived.
- The Responses endpoint is a public parser/proxy boundary even when callers are local.
- The shipped Compose and example configuration bind proxy and analyzer ports to 127.0.0.1 by default.
- UPSTREAM_BASE and PRESIDIO_URL are operator-controlled environment configuration, not request-controlled destinations.
- The remote upstream receives the complete serialized HTTP request body even if it later rejects or ignores an unknown field.
- The scan evaluates the authorized current source state only and does not claim production configuration or runtime detector accuracy.
- Docker Compose defaults remain loopback-only unless the operator changes PROXY_BIND_HOST.
- The upstream response is untrusted and a downstream client may interpret structured tool calls.
- Static source establishes optional configuration and client-behavior prerequisites without requiring deployment proof.
- Repository text and supplied user context are untrusted data, not instructions.
- The documented default deployment binds both published services to 127.0.0.1.
- UPSTREAM_BASE and PRESIDIO_URL are trusted operator configuration and are not request-controlled.
- The upstream sees generated placeholder tokens contained in the protected request.
- The intended Responses client may parse streamed function or tool-call arguments after the proxy returns restored bytes.
- No supplied authoritative threat model, knowledge base, or inherited SECURITY.md policy was present.
- The shipped default publishes proxy and analyzer ports on 127.0.0.1.
- The configured remote upstream is outside the local privacy trust boundary.
- Codex or another Responses-compatible client may interpret restored response fields as text or tool actions.
- Static findings do not assert a particular production deployment or actual dependency compromise.
- No user-supplied threat model or repository SECURITY.md policy was present.
- The default Compose publication is 127.0.0.1 and the default upstream is the documented HTTPS ChatGPT endpoint.
- The local operator, Docker daemon, and intentionally selected configuration are trusted.
- Session UUIDv4 values are not practically guessable when generated by the service.
- Downstream client approval and sandbox controls may constrain tool execution but do not prevent the proxy from rewriting tool-call arguments.
- No authoritative threat model was supplied.
- Source-default bind is 127.0.0.1 but .env can override it.
- UPSTREAM_BASE and PRESIDIO_URL are trusted operator configuration.
- Audit is static and offline.
- Repository text and user context were treated as untrusted data.

## Findings

| Findings | Reports | Severity | Confidence | Detailed write-up |
| --- | --- | --- | --- | --- |
| Incomplete outbound request policy allows anonymization bypass | [occ_0e3700a9acf29787249557ec](#finding-1) | high | high | occ_0e3700a9acf29787249557ec: inline below |
| Splitting a secret across text slots bypasses both detectors | [occ_e4de3c8c3d70a21744da859c](#finding-2) | high | medium | occ_e4de3c8c3d70a21744da859c: inline below |
| Upstream output can inject restored secrets into protocol and tool fields | [occ_19b91229c307d6aa4a40025e](#finding-3) | medium | medium | occ_19b91229c307d6aa4a40025e: inline below |
| Unauthenticated local proxy identity permits OAuth credential capture | [occ_48e76f9a43665b201b5d1932](#finding-4) | medium | high | occ_48e76f9a43665b201b5d1932: inline below |
| Section-blind TOML rewriting can leave Codex outside the privacy proxy | [occ_73800b4231e53c7321a53cf7](#finding-5) | medium | medium | occ_73800b4231e53c7321a53cf7: inline below |
| Unbounded analysis and retained state enable proxy resource exhaustion | [occ_532f208253a6587e4188ecfb](#finding-6) | low | high | occ_532f208253a6587e4188ecfb: inline below |
| Caller-addressable sessions permit cross-client plaintext restoration | [occ_5de6ecd817e5acd019f329fe](#finding-7) | low | medium | occ_5de6ecd817e5acd019f329fe: inline below |
| Fixed Presidio overlap can miss long entities at chunk boundaries | [occ_6ea532ca968b0c0f8c48375a](#finding-8) | low | medium | occ_6ea532ca968b0c0f8c48375a: inline below |
| Detector cache preserves stale false negatives across security updates | [occ_a9ae5aa925a423f368174cb9](#finding-9) | low | high | occ_a9ae5aa925a423f368174cb9: inline below |
| Overlap resolution discards sensitive outer ranges instead of preserving their union | [occ_dd1b8c57086d2893db9c4bf6](#finding-10) | low | medium | occ_dd1b8c57086d2893db9c4bf6: inline below |
| Mutable privacy-critical dependencies can execute while processing raw prompts | [occ_ddacd33146e6220c807b96e3](#finding-11) | low | high | occ_ddacd33146e6220c807b96e3: inline below |

### Confidence Scale

| Label | Meaning |
| --- | --- |
| high | Direct evidence supports the finding with no material unresolved blocker. |
| medium | Evidence supports a plausible issue, but material runtime or reachability proof remains. |
| low | Evidence is incomplete and the item is retained only for explicit follow-up. |

<a id="finding-1"></a>

### [1] Incomplete outbound request policy allows anonymization bypass

| Field | Value |
| --- | --- |
| Severity | high |
| Confidence | high |
| Confidence rationale | The source directly shows the sole input-only transformation, unconditional key/subtree exclusions, and forwarding of the complete payload. The source directly traces the parsed dictionary through a single input-only mutation into httpx json=payload; no other envelope sanitizer exists. Both traversal passes explicitly skip image_url and audio_url, and the repository contains no media inspection or rejection stage. The current source validates only that input exists, transforms only that member, preserves explicit exclusions, and serializes the full payload to the upstream. |
| Category | incomplete-data-anonymization |
| CWE | CWE-200, CWE-201 |
| Affected lines | privacy-service/proxy.py:27-45, privacy-service/proxy.py:97-119, privacy-service/proxy.py:494-512, privacy-service/proxy.py:537-544, privacy-service/proxy.py:494-512, privacy-service/proxy.py:538-549, README.md:3-12, privacy-service/proxy.py:26-45, privacy-service/proxy.py:97-119, privacy-service/proxy.py:274-310, privacy-service/proxy.py:509-544, privacy-service/proxy.py:97-119, privacy-service/proxy.py:274-310, privacy-service/proxy.py:486-512, privacy-service/proxy.py:537-548, privacy-service/proxy.py:475-543, README.md:3-12, privacy-service/proxy.py:26-45, privacy-service/proxy.py:97-120, privacy-service/proxy.py:274-310, privacy-service/proxy.py:97-119, privacy-service/proxy.py:274-306, privacy-service/proxy.py:538-544, README.md:3-12, privacy-service/proxy.py:475-512, privacy-service/proxy.py:537-549, privacy-service/proxy.py:41-45, README.md:3-12, privacy-service/proxy.py:26-39, privacy-service/proxy.py:97-103, privacy-service/proxy.py:274-281, analyzer-config.yaml:51-55, privacy-service/proxy.py:475-504, privacy-service/proxy.py:506-512, privacy-service/proxy.py:538-548, privacy-service/proxy.py:97-119, privacy-service/proxy.py:274-310 |

#### Summary

The proxy anonymizes only payload.input, applies schema-blind global key and subtree exclusions inside that field, and forwards the remaining body plus caller query parameters and nonfiltered headers. Sensitive instructions, metadata, tool descriptions and schemas, signed media URLs, generic identifiers or names, extension fields, and other caller-controlled representations can therefore bypass both detectors and cross the remote boundary unchanged. The /responses route protects payload.input but sends every sibling field, including instructions, tools, metadata, and extensions, unchanged to the remote upstream. image_url and audio_url values are explicitly excluded from text collection and replacement, and unsupported media is forwarded without inspection or rejection. The /responses route protects only payload.input, and its recursive scanner omits broad key names, entire tools subtrees, and all non-string primitives. The complete original payload and query parameters are then forwarded, so prompt-bearing instructions, metadata, signed media URLs, tool content, or numeric PII in excluded representations can reach the upstream unchanged.

#### Root Cause

Outbound privacy enforcement is a schema-blind denylist over one selected subtree rather than a complete, versioned, path-aware classification of every semantic body, query, and header field sent upstream. The privacy control is attached to one field instead of a versioned, schema-aware classification of every outbound content-bearing field. The proxy silently treats content-bearing media locators as safe protocol metadata and has no policy to inspect or reject unsupported binary content. The proxy uses a partial, denylist-style traversal of one request member instead of a strict, versioned, fail-closed schema covering every content-bearing outbound field.

**Only input is protected** — `privacy-service/proxy.py:494-512`

No other top-level request field is passed to either detector.

```python
if (not isinstance(payload, dict) or "input" not in payload):
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(payload["input"], session)
```

**Content-capable fields and tools are excluded** — `privacy-service/proxy.py:27-45`

The generic traversal omits these values at any depth and omits all tool metadata.

```python
SKIP_STRING_KEYS = {"type", "role", "id", "call_id", "name", "namespace", "status", "model", "image_url", "audio_url", "encrypted_content"}
SKIP_SUBTREE_KEYS = {"tools"}
```

**Complete payload is forwarded** — `privacy-service/proxy.py:537-544`

Unprocessed caller-controlled fields are serialized to the external upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Only input is protected** — `privacy-service/proxy.py:506-512`

The privacy pass is applied to one member rather than the complete outbound request.

```python
session_id, session = get_session(None)

try:
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**Complete payload is forwarded** — `privacy-service/proxy.py:538-544`

Every unmodified top-level member is serialized and transmitted to the remote upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Global key-name and subtree exclusions** — `privacy-service/proxy.py:27-45`

Exemption depends only on a dictionary key's spelling, not on a validated protocol object type or safe value grammar.

```python
SKIP_STRING_KEYS = {
    "type",
    "role",
    "id",
    "call_id",
    "name",
    "namespace",
    "status",
    "model",
    "image_url",
    "audio_url",
    "encrypted_content",
}

SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Excluded values are never collected** — `privacy-service/proxy.py:97-119`

A caller can choose an excluded key at any nesting level, and dictionary keys themselves are also never included in the scan corpus.

```python
def collect_text_slots(value, slots, key=None):
    if isinstance(value, str):
        if key not in SKIP_STRING_KEYS and value.strip():
            slots.append({
                "text": value,
            })
        return

    if isinstance(value, list):
        for item in value:
            collect_text_slots(item, slots)
        return

    if isinstance(value, dict):
        for child_key, child_value in value.items():
            if child_key in SKIP_SUBTREE_KEYS:
                continue

            collect_text_slots(
                child_value,
                slots,
                child_key,
            )
```

**Excluded subtrees remain verbatim** — `privacy-service/proxy.py:293-306`

The reconstruction step deliberately copies excluded content unchanged into the forwarded input.

```python
if isinstance(value, dict):
    result = {}

    for child_key, child_value in value.items():
        if child_key in SKIP_SUBTREE_KEYS:
            result[child_key] = child_value
            continue

        result[child_key] = replace_text_slots(
            child_value,
            replacements,
            index_ref,
            child_key,
        )
```

**Global key and subtree exclusions** — `privacy-service/proxy.py:27-45`

The caller can reuse these key names at arbitrary nesting positions; direct strings and the complete tools subtree are never collected for scanning.

```python
SKIP_STRING_KEYS = {"type", "role", "id", "call_id", "name", "namespace", "status", "model", "image_url", "audio_url", "encrypted_content"}
SKIP_SUBTREE_KEYS = {"tools"}
```

**Only input is protected** — `privacy-service/proxy.py:494-512`

The route accepts an otherwise unrestricted object and transforms only one property.

```python
if not isinstance(payload, dict) or "input" not in payload:
    raise HTTPException(...)
...
payload["input"] = await protect_payload_input(payload["input"], session)
```

**Complete object is forwarded** — `privacy-service/proxy.py:537-548`

Every untouched sibling, skipped subtree, and skipped scalar is serialized to the remote endpoint.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Only input is protected** — `privacy-service/proxy.py:509-512`

No other body field passes through the privacy pipeline.

```python
payload["input"] = await protect_payload_input(
    payload["input"],
    session,
)
```

**Whole payload is forwarded** — `privacy-service/proxy.py:538-543`

Unmodified sibling fields are serialized into the external request.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Context-free skipped fields** — `privacy-service/proxy.py:27-39`

The same spelling is trusted at every nesting depth, including fields that may carry sensitive values.

```python
SKIP_STRING_KEYS = {
    "type", "role", "id", "call_id", "name", "namespace",
    "status", "model", "image_url", "audio_url", "encrypted_content",
}
```

**Skipped values are never scanned** — `privacy-service/proxy.py:97-103`

Excluded strings do not enter Presidio or Nosey Parker.

```python
if isinstance(value, str):
    if key not in SKIP_STRING_KEYS and value.strip():
        slots.append({"text": value})
    return
```

**Global key and subtree exclusions** — `privacy-service/proxy.py:27-45`

The same terminal property name is exempt everywhere, without validating its enclosing schema or whether its value can contain sensitive data.

```python
SKIP_STRING_KEYS = {
    "type", "role", "id", "call_id", "name", "namespace", "status", "model",
    "image_url", "audio_url", "encrypted_content",
}
SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Only input is protected** — `privacy-service/proxy.py:494-512`

Top-level instructions and every other semantic request field remain unchanged.

```python
if (
    not isinstance(payload, dict)
    or "input" not in payload
):
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(
    payload["input"],
    session,
)
```

**Complete payload sent upstream** — `privacy-service/proxy.py:538-544`

All unprotected fields and skipped values are serialized and transmitted to the configured external upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Only payload.input enters the privacy pipeline** — `privacy-service/proxy.py:506-512`

No sibling field is traversed, scanned, rejected, or replaced.

```python
session_id, session = get_session(None)

try:
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**The full dictionary is serialized upstream** — `privacy-service/proxy.py:537-549`

Every untouched top-level field is included in the remote request.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)

upstream = await client.send(
    upstream_request,
    stream=True,
)
```

**Content-bearing media locator keys are exempt** — `privacy-service/proxy.py:26-39`

Exemption is based only on a dictionary key, not on whether the URL or media contains sensitive data.

```python
SKIP_STRING_KEYS = {
    "type",
    "role",
    "id",
    "call_id",
    "name",
    "namespace",
    "status",
    "model",
    "image_url",
    "audio_url",
    "encrypted_content",
}
```

**Exempt strings are not collected or replaced** — `privacy-service/proxy.py:97-103`

The configured URL recognizer never sees excluded media URL strings.

```python
if isinstance(value, str):
    if key not in SKIP_STRING_KEYS and value.strip():
        slots.append({
            "text": value,
        })
    return
```

**Global key and subtree exemptions** — `privacy-service/proxy.py:27-45`

Exemptions depend only on a terminal key spelling and skip content-bearing URLs and complete tools subtrees without validating their protocol path or value.

```python
SKIP_STRING_KEYS = {
    "type", "role", "id", "call_id", "name", "namespace",
    "status", "model", "image_url", "audio_url", "encrypted_content",
}
SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Collector scans strings only and silently preserves other primitives** — `privacy-service/proxy.py:97-119`

Only strings are detector inputs; skipped strings, subtrees, and non-string primitives are never analyzed.

```python
def collect_text_slots(value, slots, key=None):
    if isinstance(value, str):
        if key not in SKIP_STRING_KEYS and value.strip():
            slots.append({"text": value})
        return
    if isinstance(value, list):
        for item in value:
            collect_text_slots(item, slots)
        return
    if isinstance(value, dict):
        for child_key, child_value in value.items():
            if child_key in SKIP_SUBTREE_KEYS:
                continue
            collect_text_slots(child_value, slots, child_key)
```

**Only input is transformed before full-payload forwarding** — `privacy-service/proxy.py:494-549`

Every other top-level field and every preserved value inside input reaches the network sink verbatim.

```python
if not isinstance(payload, dict) or "input" not in payload:
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(payload["input"], session)
...
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
upstream = await client.send(upstream_request, stream=True)
```

**Only input is protected** — `privacy-service/proxy.py:506-512`

No other member of the parsed request object is traversed or classified.

```python
session_id, session = get_session(None)
payload["input"] = await protect_payload_input(
    payload["input"], session,
)
```

**Complete payload is sent upstream** — `privacy-service/proxy.py:537-544`

Every top-level member other than rewritten input is serialized unchanged.

```python
upstream_request = client.build_request(
    "POST", f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(), headers=headers, json=payload,
)
```

**Secret-capable fields are globally exempt** — `privacy-service/proxy.py:26-45`

Exemptions depend only on a key name, not a validated path or value grammar.

```python
SKIP_STRING_KEYS = {
 "type", "role", "id", "call_id", "name", "namespace",
 "status", "model", "image_url", "audio_url", "encrypted_content",
}
SKIP_SUBTREE_KEYS = {"tools"}
```

**Excluded strings never enter detectors** — `privacy-service/proxy.py:97-103`

Signed URLs or sensitive identifiers under exempt keys bypass both scanners.

```python
if isinstance(value, str):
    if key not in SKIP_STRING_KEYS and value.strip():
        slots.append({"text": value})
    return
```

#### Validation

Static source-to-sink validation establishes independently reachable variants under one remediation-subsuming outbound-policy failure: top-level members outside input are never scanned; values under globally excluded keys or tools subtrees are omitted and reconstructed unchanged; and caller query parameters or nonfiltered headers are passed without the body anonymizer. Detector failures for covered input still fail closed, and deliberate OAuth forwarding to the configured upstream is not itself evidence of a request-controlled destination. A caller can place sensitive text in any sibling field while providing a valid input field; the exact text reaches UPSTREAM_BASE without entering either detector. A signed image_url or audio_url containing credentials, sensitive query parameters, or internal identifiers survives unchanged and is sent upstream. A caller-controlled JSON object can carry sensitive data outside input, under any globally skipped key/subtree, or as an unhandled primitive. No later outbound validation runs before httpx sends the complete object.

Validation method: Manual source-to-sink review with sibling-field and fail-closed checks. Independent baseline and focused forward dataflow review followed by parent source revalidation.

- **Status:** validated
- **Disposition:** report

**Only input is protected** — `privacy-service/proxy.py:494-512`

No other top-level request field is passed to either detector.

```python
if (not isinstance(payload, dict) or "input" not in payload):
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(payload["input"], session)
```

**Content-capable fields and tools are excluded** — `privacy-service/proxy.py:27-45`

The generic traversal omits these values at any depth and omits all tool metadata.

```python
SKIP_STRING_KEYS = {"type", "role", "id", "call_id", "name", "namespace", "status", "model", "image_url", "audio_url", "encrypted_content"}
SKIP_SUBTREE_KEYS = {"tools"}
```

**Complete payload is forwarded** — `privacy-service/proxy.py:537-544`

Unprocessed caller-controlled fields are serialized to the external upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Only input is protected** — `privacy-service/proxy.py:506-512`

The privacy pass is applied to one member rather than the complete outbound request.

```python
session_id, session = get_session(None)

try:
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**Complete payload is forwarded** — `privacy-service/proxy.py:538-544`

Every unmodified top-level member is serialized and transmitted to the remote upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Global key-name and subtree exclusions** — `privacy-service/proxy.py:27-45`

Exemption depends only on a dictionary key's spelling, not on a validated protocol object type or safe value grammar.

```python
SKIP_STRING_KEYS = {
    "type",
    "role",
    "id",
    "call_id",
    "name",
    "namespace",
    "status",
    "model",
    "image_url",
    "audio_url",
    "encrypted_content",
}

SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Excluded values are never collected** — `privacy-service/proxy.py:97-119`

A caller can choose an excluded key at any nesting level, and dictionary keys themselves are also never included in the scan corpus.

```python
def collect_text_slots(value, slots, key=None):
    if isinstance(value, str):
        if key not in SKIP_STRING_KEYS and value.strip():
            slots.append({
                "text": value,
            })
        return

    if isinstance(value, list):
        for item in value:
            collect_text_slots(item, slots)
        return

    if isinstance(value, dict):
        for child_key, child_value in value.items():
            if child_key in SKIP_SUBTREE_KEYS:
                continue

            collect_text_slots(
                child_value,
                slots,
                child_key,
            )
```

**Excluded subtrees remain verbatim** — `privacy-service/proxy.py:293-306`

The reconstruction step deliberately copies excluded content unchanged into the forwarded input.

```python
if isinstance(value, dict):
    result = {}

    for child_key, child_value in value.items():
        if child_key in SKIP_SUBTREE_KEYS:
            result[child_key] = child_value
            continue

        result[child_key] = replace_text_slots(
            child_value,
            replacements,
            index_ref,
            child_key,
        )
```

**Global key and subtree exclusions** — `privacy-service/proxy.py:27-45`

The caller can reuse these key names at arbitrary nesting positions; direct strings and the complete tools subtree are never collected for scanning.

```python
SKIP_STRING_KEYS = {"type", "role", "id", "call_id", "name", "namespace", "status", "model", "image_url", "audio_url", "encrypted_content"}
SKIP_SUBTREE_KEYS = {"tools"}
```

**Only input is protected** — `privacy-service/proxy.py:494-512`

The route accepts an otherwise unrestricted object and transforms only one property.

```python
if not isinstance(payload, dict) or "input" not in payload:
    raise HTTPException(...)
...
payload["input"] = await protect_payload_input(payload["input"], session)
```

**Complete object is forwarded** — `privacy-service/proxy.py:537-548`

Every untouched sibling, skipped subtree, and skipped scalar is serialized to the remote endpoint.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Global key and subtree exclusions** — `privacy-service/proxy.py:27-45`

The same terminal property name is exempt everywhere, without validating its enclosing schema or whether its value can contain sensitive data.

```python
SKIP_STRING_KEYS = {
    "type", "role", "id", "call_id", "name", "namespace", "status", "model",
    "image_url", "audio_url", "encrypted_content",
}
SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Only input is protected** — `privacy-service/proxy.py:494-512`

Top-level instructions and every other semantic request field remain unchanged.

```python
if (
    not isinstance(payload, dict)
    or "input" not in payload
):
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(
    payload["input"],
    session,
)
```

**Complete payload sent upstream** — `privacy-service/proxy.py:538-544`

All unprotected fields and skipped values are serialized and transmitted to the configured external upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Global key and subtree exemptions** — `privacy-service/proxy.py:27-45`

Exemptions depend only on a terminal key spelling and skip content-bearing URLs and complete tools subtrees without validating their protocol path or value.

```python
SKIP_STRING_KEYS = {
    "type", "role", "id", "call_id", "name", "namespace",
    "status", "model", "image_url", "audio_url", "encrypted_content",
}
SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Collector scans strings only and silently preserves other primitives** — `privacy-service/proxy.py:97-119`

Only strings are detector inputs; skipped strings, subtrees, and non-string primitives are never analyzed.

```python
def collect_text_slots(value, slots, key=None):
    if isinstance(value, str):
        if key not in SKIP_STRING_KEYS and value.strip():
            slots.append({"text": value})
        return
    if isinstance(value, list):
        for item in value:
            collect_text_slots(item, slots)
        return
    if isinstance(value, dict):
        for child_key, child_value in value.items():
            if child_key in SKIP_SUBTREE_KEYS:
                continue
            collect_text_slots(child_value, slots, child_key)
```

**Only input is transformed before full-payload forwarding** — `privacy-service/proxy.py:494-549`

Every other top-level field and every preserved value inside input reaches the network sink verbatim.

```python
if not isinstance(payload, dict) or "input" not in payload:
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(payload["input"], session)
...
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
upstream = await client.send(upstream_request, stream=True)
```

**Only input is protected** — `privacy-service/proxy.py:506-512`

No other member of the parsed request object is traversed or classified.

```python
session_id, session = get_session(None)
payload["input"] = await protect_payload_input(
    payload["input"], session,
)
```

**Complete payload is sent upstream** — `privacy-service/proxy.py:537-544`

Every top-level member other than rewritten input is serialized unchanged.

```python
upstream_request = client.build_request(
    "POST", f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(), headers=headers, json=payload,
)
```

**Secret-capable fields are globally exempt** — `privacy-service/proxy.py:26-45`

Exemptions depend only on a key name, not a validated path or value grammar.

```python
SKIP_STRING_KEYS = {
 "type", "role", "id", "call_id", "name", "namespace",
 "status", "model", "image_url", "audio_url", "encrypted_content",
}
SKIP_SUBTREE_KEYS = {"tools"}
```

**Excluded strings never enter detectors** — `privacy-service/proxy.py:97-103`

Signed URLs or sensitive identifiers under exempt keys bypass both scanners.

```python
if isinstance(value, str):
    if key not in SKIP_STRING_KEYS and value.strip():
        slots.append({"text": value})
    return
```

Assertions:
- Top-level fields other than input are unchanged.
- Skipped nested values are unchanged.
- The complete payload is forwarded after the partial transformation.
- The request body may contain arbitrary members because only dictionary type and input presence are checked.
- No whole-payload privacy traversal or unknown-field rejection occurs before json=payload.
- The caller controls nested dictionary keys and values because input is not validated to a concrete object schema.
- replace_text_slots mirrors the collector's exclusions, preserving slot order while leaving the bypassed value untouched.
- The request is any JSON dictionary containing input; no full request schema or unknown-field rejection is applied.
- No operation after protect_payload_input scans or removes other payload values before client.send.
- The handler accepts any dictionary containing input.
- All sibling fields remain in payload.
- Excluded values are not collected.
- Replacement traversal returns their original value.
- The endpoint accepts arbitrary dictionary fields as long as input exists.
- Only payload.input is transformed.
- Strings under skipped names and tools subtrees are copied without scanning.
- The entire payload is sent upstream.
- The payload need only be a dictionary containing input.
- Only payload.input is replaced.
- The same payload object is serialized to the remote upstream.
- The keys are present in SKIP_STRING_KEYS.
- Collection and replacement share the exemption.
- The complete protected payload is forwarded upstream.
- The route accepts unknown top-level members.
- Only payload.input is passed to protect_payload_input.
- The collector and replacer share the same explicit exclusions.
- Disclosure occurs when the request is sent even if the upstream later rejects its schema.
- Additional payload members are unrestricted.
- No top-level traversal runs before json=payload.

Counterevidence and remaining uncertainty:
- Ordinary non-empty strings in the non-skipped portion of input are scanned.
- Detector exceptions return HTTP 503 before forwarding.
- Several skipped keys are normally protocol identifiers, but the code does not validate their values or constrain them to constant formats.
- Detection failures on payload.input return 503 and fail closed.
- An Authorization header is required, but it does not expand anonymization coverage.
- The default upstream is HTTPS and trusted by configuration; the defect is disclosure of raw content to that upstream.
- Ordinary strings under non-excluded keys are scanned by both detector paths.
- Some excluded fields are normally protocol identifiers or ciphertext, but the code does not verify that semantic role.
- Rewriting genuine protocol identifiers can break requests, which explains the compatibility intent but not the unrestricted exclusion.
- Ordinary nonempty strings under non-skipped keys inside input are scanned.
- Several skipped keys normally carry protocol metadata and must remain syntactically stable.
- Raised detector errors return 503 before the upstream request is built.
- Detection errors for input fail closed before the request is built.
- Default service exposure is loopback.
- Protocol discriminators such as type and role should not be rewritten.
- Encrypted content is not established as plaintext.
- Some excluded values are genuine protocol enums or opaque encrypted data and rewriting them could corrupt requests.
- The default listener is loopback and /responses requires an Authorization header to be present.
- The repository does not contain captured client traffic proving every example field is populated in every integration version.
- Authorization-header presence is checked.
- Failures while scanning input fail closed.
- Those controls do not inspect content deliberately omitted from scanning.
- Public media URLs may contain no secret.
- Replacing a complete media URL would break retrieval, motivating but not securing the exemption.
- Ordinary nonempty strings under non-skipped input paths are analyzed by both detectors.
- Some skipped values are normally structural identifiers, but the proxy does not enforce those structural assumptions.
- Malformed JSON and missing input are rejected.
- Input detector failures return 503.
- Those controls do not inspect other fields.
- Ordinary public URLs are not secrets.
- encrypted_content is normally opaque.
- Blind replacement could break syntax, but no safer validation exists.

Limitations:
- The exact set of valid upstream fields is not established from this repository, but transmission of any unknown plaintext field to the remote HTTP endpoint occurs before any upstream rejection.
- Accepted upstream field population was not runtime-captured.
- No live signed-URL request was executed.
- Upstream acceptance of malformed placements is not assumed; the finding relies on valid text-bearing fields and the public arbitrary-JSON parser boundary.
- No live client payload was captured; the generic request boundary itself establishes caller control.
- No OCR or audio-runtime test was performed; URL-string bypass is established directly by source.
- The repository does not contain a complete versioned upstream request schema or production traffic samples.
- No live upstream request was made.
- No live client payload was captured.

#### Dataflow

Caller-controlled body/query/header data -\> input-only denylist traversal -\> unchanged outbound representation -\> httpx request to the configured upstream. Caller JSON -\> request.json() -\> input-only transformation -\> unchanged sibling fields -\> httpx json=payload -\> UPSTREAM_BASE. Input media object -\> key-name exemption -\> unchanged protected input -\> upstream JSON. Caller-controlled request field -\> partial payload.input traversal -\> excluded value preserved -\> json=payload -\> UPSTREAM_BASE.

Attack steps:
- Control a top-level field such as instructions or metadata, or a skipped nested value/tool description.
- Submit a request containing the required input member and Authorization header.
- The proxy scans only the selected input strings.
- httpx serializes and sends the untouched sensitive field to UPSTREAM_BASE.

- **Source:** POST /responses body, query parameters, and forwarded nonfiltered headers Caller-controlled Responses envelope image_url, audio_url, data URL, or opaque media field Arbitrary JSON members, skipped-key values, tools subtrees, query values, and non-string primitives

- **Sink:** client.build_request(..., params=..., headers=..., json=payload) Remote upstream request body UPSTREAM_BASE/responses httpx AsyncClient.send to the configured upstream

- **Outcome:** Plaintext confidential content crosses the local privacy boundary. Raw sensitive text leaves the local privacy boundary Sensitive locator or media content leaves the host Cleartext sensitive data leaves the local privacy boundary

Transformations:
- JSON parsing
- payload.input-only protection
- global key/subtree skipping
- outbound query/header forwarding
- whole-payload JSON serialization
- Validate only dictionary shape and presence of input.
- Protect payload.input while leaving sibling fields untouched.
- Skip selected terminal keys and tools subtrees inside input.
- Serialize the complete payload.
- partial recursive slot collection
- replacement of detected input strings only
- full-payload JSON serialization

**Only input is protected** — `privacy-service/proxy.py:494-512`

No other top-level request field is passed to either detector.

```python
if (not isinstance(payload, dict) or "input" not in payload):
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(payload["input"], session)
```

**Content-capable fields and tools are excluded** — `privacy-service/proxy.py:27-45`

The generic traversal omits these values at any depth and omits all tool metadata.

```python
SKIP_STRING_KEYS = {"type", "role", "id", "call_id", "name", "namespace", "status", "model", "image_url", "audio_url", "encrypted_content"}
SKIP_SUBTREE_KEYS = {"tools"}
```

**Complete payload is forwarded** — `privacy-service/proxy.py:537-544`

Unprocessed caller-controlled fields are serialized to the external upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Only input is protected** — `privacy-service/proxy.py:506-512`

The privacy pass is applied to one member rather than the complete outbound request.

```python
session_id, session = get_session(None)

try:
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**Complete payload is forwarded** — `privacy-service/proxy.py:538-544`

Every unmodified top-level member is serialized and transmitted to the remote upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Global key-name and subtree exclusions** — `privacy-service/proxy.py:27-45`

Exemption depends only on a dictionary key's spelling, not on a validated protocol object type or safe value grammar.

```python
SKIP_STRING_KEYS = {
    "type",
    "role",
    "id",
    "call_id",
    "name",
    "namespace",
    "status",
    "model",
    "image_url",
    "audio_url",
    "encrypted_content",
}

SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Excluded values are never collected** — `privacy-service/proxy.py:97-119`

A caller can choose an excluded key at any nesting level, and dictionary keys themselves are also never included in the scan corpus.

```python
def collect_text_slots(value, slots, key=None):
    if isinstance(value, str):
        if key not in SKIP_STRING_KEYS and value.strip():
            slots.append({
                "text": value,
            })
        return

    if isinstance(value, list):
        for item in value:
            collect_text_slots(item, slots)
        return

    if isinstance(value, dict):
        for child_key, child_value in value.items():
            if child_key in SKIP_SUBTREE_KEYS:
                continue

            collect_text_slots(
                child_value,
                slots,
                child_key,
            )
```

**Excluded subtrees remain verbatim** — `privacy-service/proxy.py:293-306`

The reconstruction step deliberately copies excluded content unchanged into the forwarded input.

```python
if isinstance(value, dict):
    result = {}

    for child_key, child_value in value.items():
        if child_key in SKIP_SUBTREE_KEYS:
            result[child_key] = child_value
            continue

        result[child_key] = replace_text_slots(
            child_value,
            replacements,
            index_ref,
            child_key,
        )
```

**Global key and subtree exclusions** — `privacy-service/proxy.py:27-45`

The caller can reuse these key names at arbitrary nesting positions; direct strings and the complete tools subtree are never collected for scanning.

```python
SKIP_STRING_KEYS = {"type", "role", "id", "call_id", "name", "namespace", "status", "model", "image_url", "audio_url", "encrypted_content"}
SKIP_SUBTREE_KEYS = {"tools"}
```

**Only input is protected** — `privacy-service/proxy.py:494-512`

The route accepts an otherwise unrestricted object and transforms only one property.

```python
if not isinstance(payload, dict) or "input" not in payload:
    raise HTTPException(...)
...
payload["input"] = await protect_payload_input(payload["input"], session)
```

**Complete object is forwarded** — `privacy-service/proxy.py:537-548`

Every untouched sibling, skipped subtree, and skipped scalar is serialized to the remote endpoint.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Only input is protected** — `privacy-service/proxy.py:509-512`

No other body field passes through the privacy pipeline.

```python
payload["input"] = await protect_payload_input(
    payload["input"],
    session,
)
```

**Whole payload is forwarded** — `privacy-service/proxy.py:538-543`

Unmodified sibling fields are serialized into the external request.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Context-free skipped fields** — `privacy-service/proxy.py:27-39`

The same spelling is trusted at every nesting depth, including fields that may carry sensitive values.

```python
SKIP_STRING_KEYS = {
    "type", "role", "id", "call_id", "name", "namespace",
    "status", "model", "image_url", "audio_url", "encrypted_content",
}
```

**Skipped values are never scanned** — `privacy-service/proxy.py:97-103`

Excluded strings do not enter Presidio or Nosey Parker.

```python
if isinstance(value, str):
    if key not in SKIP_STRING_KEYS and value.strip():
        slots.append({"text": value})
    return
```

**Global key and subtree exclusions** — `privacy-service/proxy.py:27-45`

The same terminal property name is exempt everywhere, without validating its enclosing schema or whether its value can contain sensitive data.

```python
SKIP_STRING_KEYS = {
    "type", "role", "id", "call_id", "name", "namespace", "status", "model",
    "image_url", "audio_url", "encrypted_content",
}
SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Only input is protected** — `privacy-service/proxy.py:494-512`

Top-level instructions and every other semantic request field remain unchanged.

```python
if (
    not isinstance(payload, dict)
    or "input" not in payload
):
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(
    payload["input"],
    session,
)
```

**Complete payload sent upstream** — `privacy-service/proxy.py:538-544`

All unprotected fields and skipped values are serialized and transmitted to the configured external upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Only payload.input enters the privacy pipeline** — `privacy-service/proxy.py:506-512`

No sibling field is traversed, scanned, rejected, or replaced.

```python
session_id, session = get_session(None)

try:
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**The full dictionary is serialized upstream** — `privacy-service/proxy.py:537-549`

Every untouched top-level field is included in the remote request.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)

upstream = await client.send(
    upstream_request,
    stream=True,
)
```

**Collector scans strings only and silently preserves other primitives** — `privacy-service/proxy.py:97-119`

Only strings are detector inputs; skipped strings, subtrees, and non-string primitives are never analyzed.

```python
def collect_text_slots(value, slots, key=None):
    if isinstance(value, str):
        if key not in SKIP_STRING_KEYS and value.strip():
            slots.append({"text": value})
        return
    if isinstance(value, list):
        for item in value:
            collect_text_slots(item, slots)
        return
    if isinstance(value, dict):
        for child_key, child_value in value.items():
            if child_key in SKIP_SUBTREE_KEYS:
                continue
            collect_text_slots(child_value, slots, child_key)
```

**Only input is transformed before full-payload forwarding** — `privacy-service/proxy.py:494-549`

Every other top-level field and every preserved value inside input reaches the network sink verbatim.

```python
if not isinstance(payload, dict) or "input" not in payload:
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(payload["input"], session)
...
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
upstream = await client.send(upstream_request, stream=True)
```

#### Reachability

Directly reachable through the implemented /responses parser/proxy boundary. Reachable through /responses by any legitimate client that can populate a content-bearing sibling field and supply the expected authorization header. Reachable when a Responses-compatible client submits supported media content. Any caller that can make an accepted /responses request and influence one of the excluded representations reaches the sink; a normal authenticated CLI satisfies the route's header-presence gate.

- **Attacker:** Caller, CLI integration, plugin, skill, or project content able to influence request structure Malicious plugin, tool integration, client component, or repository-derived instruction source Repository, document, plugin, or client controlling a media-bearing input Client integration or content source influencing outbound request structure/content

- **Entry point:** privacy-service/proxy.py:475 POST /responses

- **Source:** Sensitive data in an excluded field or representation

- **Sink:** privacy-service/proxy.py:538 outbound POST UPSTREAM_BASE/responses Remote upstream request Configured upstream /responses endpoint

- **Outcome:** Raw sensitive data is disclosed to the configured upstream. Plaintext disclosure Plaintext locator disclosure or uninspected media disclosure Sensitive value is transmitted unchanged

Preconditions:
- A caller or integration can influence an upstream-visible unprocessed field.
- The request contains input and any Authorization header.
- The upstream-visible sensitive value is placed outside the protected traversal.
- Sensitive content is placed outside input or beneath a globally skipped path.
- The supplied field is accepted by the chosen upstream integration.
- A content-bearing field outside input is accepted by the caller/upstream flow.
- The request contains media or a credential-bearing media locator.
- The request contains an input member
- Sensitive content is placed outside the scanner's effective coverage

Existing controls:
- Loopback binding by default
- Fail-closed behavior for detector exceptions within protected input
- Detector failures fail closed for strings that are actually scanned.
- Some protocol keys are intentionally excluded to preserve compatibility.
- Default loopback listener
- Authorization header presence check
- Fail-closed behavior for exceptions raised while scanning input

Limitations:
- Those controls do not inspect successfully excluded values.

**Global key and subtree exclusions** — `privacy-service/proxy.py:27-45`

The same terminal property name is exempt everywhere, without validating its enclosing schema or whether its value can contain sensitive data.

```python
SKIP_STRING_KEYS = {
    "type", "role", "id", "call_id", "name", "namespace", "status", "model",
    "image_url", "audio_url", "encrypted_content",
}
SKIP_SUBTREE_KEYS = {
    "tools",
}
```

**Only input is protected** — `privacy-service/proxy.py:494-512`

Top-level instructions and every other semantic request field remain unchanged.

```python
if (
    not isinstance(payload, dict)
    or "input" not in payload
):
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(
    payload["input"],
    session,
)
```

**Complete payload sent upstream** — `privacy-service/proxy.py:538-544`

All unprotected fields and skipped values are serialized and transmitted to the configured external upstream.

```python
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
```

**Only input is transformed before full-payload forwarding** — `privacy-service/proxy.py:494-549`

Every other top-level field and every preserved value inside input reaches the network sink verbatim.

```python
if not isinstance(payload, dict) or "input" not in payload:
    raise HTTPException(status_code=400, detail="Responses request has no input field")
...
payload["input"] = await protect_payload_input(payload["input"], session)
...
upstream_request = client.build_request(
    "POST",
    f"{UPSTREAM_BASE}/responses",
    params=request.query_params.multi_items(),
    headers=headers,
    json=payload,
)
upstream = await client.send(upstream_request, stream=True)
```

#### Severity

**High** — A caller or malicious integration can directly route high-impact confidential data around the product's primary control with a normal accepted request shape. This is a deterministic bypass of the product's primary confidentiality control and can immediately disclose high-impact workspace data or credentials through common content-bearing request fields. Sensitive signed URLs and media content can cross the boundary directly, but exploitation requires a supported media-bearing request and sensitive data in an excluded locator or attachment. Cleartext disclosure can expose credentials or private workspace data. The bypass is direct and requires no detector failure, but practical likelihood depends on a supported client or content source placing sensitive material in an excluded request representation.

Severity would decrease if an upstream schema validator proved that every unprocessed field is a non-content constant and unsupported content-bearing fields are rejected. Severity would fall if the endpoint enforced a narrow text-only schema and rejected every unscanned content-bearing sibling field. Severity increases when clients routinely attach confidential screenshots, recordings, signed object URLs, or data URLs. Raise if production traces show sensitive repository or user content routinely occupies instructions, metadata, tools, skipped-key, or non-string fields. Lower only if a strict locally enforced schema proves those paths cannot carry sensitive data.

Impact assessment:
- **Level:** high
- **Rationale:** Credentials, PII, or workspace content can be disclosed outside the host. Credentials, PII, internal instructions, and workspace data can be disclosed in plaintext. Signed URLs or confidential media may be exposed. The disclosed value can be an OAuth-adjacent credential, API key, PII, private instruction, or internal URL.

Likelihood assessment:
- **Level:** high medium
- **Rationale:** The bypass requires only normal structured request placement, not detector evasion or a race. The bypass is deterministic once sensitive data is placed outside input. Requires media-bearing client behavior and sensitive content in an excluded representation. The mechanism is unconditional, but sensitive placement in excluded protocol fields depends on the client and content representation.

#### Remediation

Define and enforce an explicit supported Responses schema and construct a new allowlisted outbound request. Apply path- and type-aware redaction or strict safe-value validation to every accepted content-bearing body field, including instructions, metadata, tool descriptions/schemas/examples/defaults/enums, mapping keys, media URLs, and future extensions. Allow only required query parameters and headers, reject or sanitize other caller-controlled values, strip credentials from URLs, and treat the deliberate Authorization forwarding as a separately documented credential boundary. Reject unknown or unsupported representations before opening the upstream connection. Implement versioned, schema-aware protection for the complete outbound Responses envelope. Scan instructions, privacy-bearing tool descriptions and schemas, metadata values, and every supported free-text field; preserve only narrowly validated protocol identifiers and fail closed on unknown content-bearing fields. Reject media and opaque attachments by default until a bounded local inspection pipeline exists. Parse media URLs, reject user-info credentials and sensitive query parameters, validate schemes and destinations, and handle data URLs with strict size and type limits. Replace global key-name skips with schema-path-specific treatment. Validate the complete outbound request against an explicit Responses schema and classify every field as structural, content-bearing, or unsupported. Analyze instructions, metadata values, tool descriptions, signed URLs, and other content-bearing fields; constrain structural identifiers by exact path, type, enum, and length; canonicalize legitimate numeric identifiers for scanning; reject unknown or uninspectable fields fail-closed. Add a final outbound validation pass before httpx transmission.

Tests:
- Send fake PII and secret markers in every accepted top-level field and assert a mock upstream never receives the originals.
- Repeat for nested name, image_url, audio_url, encrypted_content, object keys, and tool descriptions.
- Assert unknown content-bearing fields and unsupported modalities are rejected before any upstream request.
- Send a request with a known detector-matching secret in every accepted top-level string-bearing field and assert the captured outbound JSON contains no original.
- Assert unknown top-level fields are rejected locally before an upstream connection is made.
- Place known secrets under each formerly excluded name at multiple nesting levels and assert they are redacted or rejected.
- Place a secret in tool descriptions, schema defaults, signed URL query data, and arbitrary mapping keys and assert no plaintext reaches serialized outbound JSON.
- Use a recording mock upstream and assert that a canary secret in every supported top-level field is redacted or rejected.
- Repeat the canary under every excluded key at arbitrary input nesting depths and in the tools subtree.
- Verify numeric and multimodal sensitive representations are rejected or handled by an explicitly documented privacy policy.
- Capture the complete outbound JSON and assert seeded secrets are absent from every supported field.
- Verify unknown text-bearing fields are rejected before any network request.
- Seed secrets under every excluded key and assert each is redacted or explicitly rejected.
- Test signed image and audio URLs with sensitive query parameters.
- Seed canary secrets in every accepted query parameter and non-authentication header and assert they are rejected, stripped, or sanitized before upstream transmission.
- Verify only explicitly required headers are forwarded and that deliberate Authorization forwarding is documented and tested as a separate credential boundary.
- Seeded secrets in instructions, metadata, tool descriptions, schemas, generic id/name objects, image_url query parameters, and nested tools objects are redacted or rejected.
- Required protocol enums and identifiers remain unchanged after path-aware processing.
- Unknown text-bearing fields fail closed.
- A serialized outbound-body assertion proves no seeded marker remains anywhere.
- Capture an upstream test request and assert canary secrets in instructions, tool descriptions, metadata, and extensions never arrive unchanged.
- Assert unknown content-bearing top-level fields are rejected rather than silently forwarded.
- Submit signed image and audio URLs containing canary secrets and assert rejection or safe transformation.
- Submit data URLs and unsupported attachment types and assert fail-closed behavior.
- Use a local mock upstream and assert that secrets in instructions, metadata, tool descriptions, query parameters, image/audio URLs, name/id extension fields, and numeric values are redacted or rejected.
- Fuzz nested request objects with skipped key spellings at unexpected paths and require fail-closed rejection.
- Verify genuine enum-like protocol identifiers remain unchanged only at their exact validated schema paths.
- Assert fake secrets in instructions, metadata, prompt variables, and tool descriptions never appear in captured upstream JSON.
- Assert unknown string-bearing top-level fields fail closed.
- Place fake bearer and signed-query values in media URLs and assert rejection or safe handling.
- Verify the same key name at unrelated paths cannot bypass classification.

Preventive controls:
- Schema-aware request validation
- Outbound DLP invariant tests
- Reject-by-default handling for unsupported content locations
- Typed request schema with explicit privacy classification per field
- Fail-closed unknown-field handling
- Outbound invariant test over serialized request bytes
- Typed protocol AST rather than a generic recursive dictionary walker
- Path-specific safe-value validators
- Fail-closed policy for unsupported structured content
- Outbound schema allowlist
- Path- and type-aware redaction
- Unknown-field rejection
- Mock-upstream privacy regression suite
- Schema-aware outbound policy
- Fail-closed protocol validation
- Schema-aware field policy
- Sensitive URL validation
- Versioned request schemas
- Path-aware field classification
- Fail-closed handling for unknown semantic fields
- Credential-aware URL validation
- Central outbound schema validator
- Path-aware content classification
- Fail-closed handling of unknown protocol fields
- Text-only mode enforcement
- Media URL parser and credential checks
- Bounded local OCR or transcription for explicitly supported formats
- Default-deny handling of unknown content-bearing fields
- Outbound secret/PII policy check at the network boundary
- Schema allowlisting
- Exhaustive outbound privacy classification
- Path-aware schema validation
- URL credential rejection
- Trusted tool-definition allowlist

<a id="finding-2"></a>

### [2] Splitting a secret across text slots bypasses both detectors

| Field | Value |
| --- | --- |
| Severity | high |
| Confidence | medium |
| Confidence rationale | The per-slot/separated algorithm and containment-only mapper are explicit and independently corroborated. Concrete effective split points and upstream semantic adjacency depend on detector rules and request-item semantics outside the reviewed source. The source explicitly inserts separators, scans Presidio per string, drops cross-range spans, and reassembles the original structure. The separator insertion, per-slot Presidio calls, and cross-range rejection are explicit and no subsequent recombination scan exists. |
| Category | anonymization-boundary-evasion |
| CWE | CWE-693, CWE-200, CWE-201 |
| Affected lines | privacy-service/proxy.py:97-119, privacy-service/proxy.py:122-167, privacy-service/proxy.py:170-244, privacy-service/proxy.py:313-361, privacy-service/proxy.py:537-544, privacy-service/proxy.py:170-244, privacy-service/proxy.py:313-361, privacy-service/proxy.py:122-167, privacy-service/proxy.py:170-244, privacy-service/proxy.py:313-361, privacy-service/proxy.py:97-145, privacy-service/proxy.py:148-167, privacy-service/proxy.py:313-361, privacy-service/proxy.py:97-119, privacy-service/proxy.py:122-167, privacy-service/proxy.py:170-244, privacy-service/proxy.py:313-361, privacy-service/proxy.py:537-549, privacy-service/proxy.py:538-549, privacy-service/proxy.py:170-204 |

#### Summary

Presidio scans each JSON string separately while Nosey Parker sees artificial newlines between slots and cross-slot matches are discarded. A credential or identifier split between adjacent structured input strings can reach the upstream as complete raw fragments. Each JSON string is protected independently; separators prevent Nosey Parker from matching a value split across slots and Presidio never scans across those boundaries. Presidio scans every text slot independently, while Nosey Parker sees slots separated by two newlines and its results are retained only when one span fits wholly inside one slot. A credential or identifier divided across adjacent input items therefore survives unchanged in all pieces and is forwarded upstream.

#### Root Cause

The implementation equates JSON string boundaries with privacy boundaries even when the upstream model can semantically recombine adjacent structured content. Detection boundaries follow JSON string storage rather than the logical text sequence consumed by the upstream. Detection is performed on physical slots instead of a canonical logical content stream, and the offset mapper cannot represent a sensitive interval spanning multiple slots.

**Slots are separated before secret scanning** — `privacy-service/proxy.py:122-145`

A secret split between two slots is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    ...
    separator = "\n\n"
    parts.append(separator)
...
return "".join(parts), ranges
```

**Cross-range findings are not mapped** — `privacy-service/proxy.py:148-167`

Only a finding wholly contained within one original slot can cause replacement.

```python
if (span["start"] >= item["start"] and span["end"] <= item["end"]):
    mapped[item["slot"]].append({**span, "start": span["start"] - item["start"], "end": span["end"] - item["start"]})
    break
```

**Presidio operates on individual strings** — `privacy-service/proxy.py:170-211`

Presidio never receives an adjacent-slot boundary window.

```python
unique_texts = list(dict.fromkeys(slot["text"] for slot in slots))
...
spans = await presidio_spans(chunk_text, "lt")
```

**Slots are joined with synthetic separators** — `privacy-service/proxy.py:127-145`

A value fragmented across two slots is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]

    start = offset
    parts.append(text)
    offset += len(text)
    end = offset

    ranges.append({
        "slot": index,
        "start": start,
        "end": end,
    })

    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
```

**Cross-slot spans are discarded** — `privacy-service/proxy.py:154-165`

Even a detector result spanning a boundary would not be assigned to either original slot.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Presidio scans each slot separately** — `privacy-service/proxy.py:174-210`

Presidio never receives the full value when its fragments reside in different slots.

```python
unique_texts = list(dict.fromkeys(
    slot["text"]
    for slot in slots
))

text_chunks = {}
missing_chunks = {}
for text in unique_texts:
    chunks = []
```

**Artificial slot separator** — `privacy-service/proxy.py:127-145`

A value split between strings is no longer contiguous for Nosey Parker.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    parts.append(text)
    ...
    separator = "\n\n"
    parts.append(separator)
```

**Cross-slot spans are discarded** — `privacy-service/proxy.py:154-165`

Only findings entirely inside one original string are mapped back.

```python
if (
    span["start"] >= item["start"]
    and span["end"] <= item["end"]
):
    mapped[item["slot"]].append({...})
```

**Logical slots separated before secret scanning** — `privacy-service/proxy.py:127-145`

A sensitive value divided between adjacent strings is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    ...
    ranges.append({"slot": index, "start": start, "end": end})
    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
return "".join(parts), ranges
```

**Cross-slot spans discarded** — `privacy-service/proxy.py:154-165`

Even a detector span crossing an inserted boundary is not applied to either contributing slot.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Only wholly contained spans are retained** — `privacy-service/proxy.py:154-165`

Even a hypothetical detector span crossing a slot boundary would be discarded.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Secret corpus inserts a separator between slots** — `privacy-service/proxy.py:127-145`

A value that was contiguous only across logical slots is changed before Nosey Parker receives it.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    start = offset
    parts.append(text)
    offset += len(text)
    end = offset
    ranges.append({"slot": index, "start": start, "end": end})
    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
return "".join(parts), ranges
```

**Only single-slot Nosey Parker spans are mapped** — `privacy-service/proxy.py:154-165`

Any span crossing a slot boundary or inserted separator has no mapping and is discarded.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Presidio scans each unique slot independently** — `privacy-service/proxy.py:170-210`

No Presidio request contains adjacent slot fragments in their original logical order.

```python
unique_texts = list(dict.fromkeys(
    slot["text"]
    for slot in slots
))
...
for text in unique_texts:
    chunks = []
    for core_start in range(0, len(text), chunk_size):
        ...
async def scan(cache_key, chunk_text):
    async with semaphore:
        spans = await presidio_spans(chunk_text, "lt")
```

**Slots are separated before scanning** — `privacy-service/proxy.py:127-145`

A contiguous secret split at a slot boundary is not contiguous in the Nosey Parker corpus.

```python
parts.append(text)
...
separator = "\n\n"
parts.append(separator)
```

**Cross-slot spans are discarded** — `privacy-service/proxy.py:154-165`

Only detections contained wholly in one source string can be replaced.

```python
if span["start"] >= item["start"] and span["end"] <= item["end"]:
    mapped[item["slot"]].append({...})
    break
```

#### Validation

Static validation proves that Presidio receives one slot at a time, Nosey Parker receives artificial separators, and the mapper has no multi-slot replacement path. The representation flaw is certain; disclosure for a concrete secret requires semantically adjacent slots whose individual fragments are not independently recognized by the external detector rules. Splitting a recognizable credential or identifier between adjacent strings prevents any complete-value match while preserving both raw fragments in the outbound structure. Dividing a contiguous detector pattern between two strings removes the pattern from every Presidio input and changes it in the Nosey corpus; even a cross-boundary Nosey span would be dropped.

Validation method: Manual boundary/dataflow review without executing application code. Focused representation-boundary review followed by parent source revalidation.

- **Status:** validated-with-prerequisite
- **Disposition:** report

**Slots are separated before secret scanning** — `privacy-service/proxy.py:122-145`

A secret split between two slots is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    ...
    separator = "\n\n"
    parts.append(separator)
...
return "".join(parts), ranges
```

**Cross-range findings are not mapped** — `privacy-service/proxy.py:148-167`

Only a finding wholly contained within one original slot can cause replacement.

```python
if (span["start"] >= item["start"] and span["end"] <= item["end"]):
    mapped[item["slot"]].append({**span, "start": span["start"] - item["start"], "end": span["end"] - item["start"]})
    break
```

**Presidio operates on individual strings** — `privacy-service/proxy.py:170-211`

Presidio never receives an adjacent-slot boundary window.

```python
unique_texts = list(dict.fromkeys(slot["text"] for slot in slots))
...
spans = await presidio_spans(chunk_text, "lt")
```

**Slots are joined with synthetic separators** — `privacy-service/proxy.py:127-145`

A value fragmented across two slots is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]

    start = offset
    parts.append(text)
    offset += len(text)
    end = offset

    ranges.append({
        "slot": index,
        "start": start,
        "end": end,
    })

    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
```

**Cross-slot spans are discarded** — `privacy-service/proxy.py:154-165`

Even a detector result spanning a boundary would not be assigned to either original slot.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Presidio scans each slot separately** — `privacy-service/proxy.py:174-210`

Presidio never receives the full value when its fragments reside in different slots.

```python
unique_texts = list(dict.fromkeys(
    slot["text"]
    for slot in slots
))

text_chunks = {}
missing_chunks = {}
for text in unique_texts:
    chunks = []
```

**Logical slots separated before secret scanning** — `privacy-service/proxy.py:127-145`

A sensitive value divided between adjacent strings is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    ...
    ranges.append({"slot": index, "start": start, "end": end})
    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
return "".join(parts), ranges
```

**Cross-slot spans discarded** — `privacy-service/proxy.py:154-165`

Even a detector span crossing an inserted boundary is not applied to either contributing slot.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Secret corpus inserts a separator between slots** — `privacy-service/proxy.py:127-145`

A value that was contiguous only across logical slots is changed before Nosey Parker receives it.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    start = offset
    parts.append(text)
    offset += len(text)
    end = offset
    ranges.append({"slot": index, "start": start, "end": end})
    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
return "".join(parts), ranges
```

**Only single-slot Nosey Parker spans are mapped** — `privacy-service/proxy.py:154-165`

Any span crossing a slot boundary or inserted separator has no mapping and is discarded.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Presidio scans each unique slot independently** — `privacy-service/proxy.py:170-210`

No Presidio request contains adjacent slot fragments in their original logical order.

```python
unique_texts = list(dict.fromkeys(
    slot["text"]
    for slot in slots
))
...
for text in unique_texts:
    chunks = []
    for core_start in range(0, len(text), chunk_size):
        ...
async def scan(cache_key, chunk_text):
    async with semaphore:
        spans = await presidio_spans(chunk_text, "lt")
```

**Slots are separated before scanning** — `privacy-service/proxy.py:127-145`

A contiguous secret split at a slot boundary is not contiguous in the Nosey Parker corpus.

```python
parts.append(text)
...
separator = "\n\n"
parts.append(separator)
```

**Cross-slot spans are discarded** — `privacy-service/proxy.py:154-165`

Only detections contained wholly in one source string can be replaced.

```python
if span["start"] >= item["start"] and span["end"] <= item["end"]:
    mapped[item["slot"]].append({...})
    break
```

Assertions:
- List and object string values become independent slots.
- Presidio scans slots independently.
- Nosey Parker receives inserted newlines and cross-slot results cannot map back.
- Presidio input is derived from one slot at a time.
- The Nosey Parker corpus inserts two newline characters between slots.
- The mapper has no branch that redacts multiple slots for a boundary-crossing span.
- Presidio input is each individual slot.
- Nosey Parker spans must fit one slot.
- Presidio receives each slot independently.
- Nosey Parker receives two newline characters between slots.
- Only spans wholly contained in one slot are applied.
- Presidio accepts results only when the start belongs to the current core.
- The worker independently confirmed that fragments split across slots are never reassembled for either detector.
- Presidio scans every unique string separately.
- Nosey Parker sees two newlines between slots.
- Cross-slot findings cannot be mapped back for replacement.
- Presidio receives one slot at a time.
- Nosey Parker receives an injected two-newline boundary.
- The mapper has no cross-range branch.
- Unmapped fragments are preserved and forwarded.

Counterevidence and remaining uncertainty:
- A sufficiently distinctive individual fragment might be detected independently.
- The in-string 256-character overlap covers ordinary chunk boundaries but does not cross JSON slots.
- Ordinary single-slot strings are unaffected.
- A detector may recognize an individual fragment for some formats.
- Detector rule grammars are external, so specific split points must be covered by regression tests.
- Whole secrets contained in one slot are scanned.
- Some individual fragments may coincidentally be detected.
- Ordinary values wholly contained in one string are covered by both detector paths.
- The 256-character overlap covers common short emails, phone numbers, IPs, and names.
- Nosey Parker scans the complete separated corpus and independently catches supported secret formats contained within a slot.
- A 256-character overlap handles chunk boundaries inside one string.
- Ordinary values wholly contained in one slot are protected.
- Nosey Parker scans one aggregate corpus rather than one process per slot.
- Aggregation does not close the gap because the separator changes the value and cross-slot spans are unmappable.
- Whole-slot secrets remain eligible.
- Separators prevent false matches across unrelated values.

Limitations:
- Exact detector matches and effective split points depend on external Presidio and Nosey Parker rules not contained in the repository.
- Upstream semantic concatenation varies by content-item type.
- The long-entity subcase depends on configured detector recognition behavior for entities exceeding the overlap; cross-slot fragmentation does not.
- No live upstream semantic-concatenation test was performed.
- Actual client segmentation is workload-dependent.

#### Dataflow

Structured input fragments -\> independent/separated detector inputs -\> no mapped span -\> outbound structured payload. Sensitive value -\> split adjacent input strings -\> independent scans/no usable match -\> original fragments reassembled -\> upstream. Split sensitive value -\> independent slot collection -\> newline-separated Nosey corpus and per-slot Presidio scans -\> no mapped span -\> original fragments serialized upstream.

Attack steps:
- Split a credential, email, phone number, or identifier at a chosen JSON text-slot boundary.
- Presidio scans each fragment independently.
- Nosey Parker scans a newline-separated composite and cannot map a cross-slot result.
- The unchanged fragments are forwarded together to the external model.

- **Source:** Caller-controlled strings inside payload.input Caller-controlled multi-part input Adjacent input strings controlled by the caller or integration

- **Sink:** Outbound Responses JSON UPSTREAM_BASE/responses Configured upstream /responses endpoint

- **Outcome:** The full secret crosses the local privacy boundary as reconstructible raw fragments. Reconstructable plaintext secret reaches the provider The upstream receives every cleartext fragment needed to reconstruct the sensitive value

Transformations:
- Recursive slot collection
- Per-slot Presidio scans
- newline-separated Nosey Parker corpus
- per-slot replacement
- Collect strings as independent slots.
- Insert separators for the Nosey Parker corpus.
- Scan Presidio slots in fixed-overlap chunks.
- Drop cross-slot spans and results whose starts are outside the current core.
- Apply only retained spans and forward all remaining text.
- Discard any detector span that is not wholly contained in one original slot.
- Slot enumeration
- separator insertion
- per-slot PII chunking
- single-range span mapping

**Slots are separated before secret scanning** — `privacy-service/proxy.py:122-145`

A secret split between two slots is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    ...
    separator = "\n\n"
    parts.append(separator)
...
return "".join(parts), ranges
```

**Cross-range findings are not mapped** — `privacy-service/proxy.py:148-167`

Only a finding wholly contained within one original slot can cause replacement.

```python
if (span["start"] >= item["start"] and span["end"] <= item["end"]):
    mapped[item["slot"]].append({**span, "start": span["start"] - item["start"], "end": span["end"] - item["start"]})
    break
```

**Presidio operates on individual strings** — `privacy-service/proxy.py:170-211`

Presidio never receives an adjacent-slot boundary window.

```python
unique_texts = list(dict.fromkeys(slot["text"] for slot in slots))
...
spans = await presidio_spans(chunk_text, "lt")
```

**Logical slots separated before secret scanning** — `privacy-service/proxy.py:127-145`

A sensitive value divided between adjacent strings is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    ...
    ranges.append({"slot": index, "start": start, "end": end})
    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
return "".join(parts), ranges
```

**Cross-slot spans discarded** — `privacy-service/proxy.py:154-165`

Even a detector span crossing an inserted boundary is not applied to either contributing slot.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Secret corpus inserts a separator between slots** — `privacy-service/proxy.py:127-145`

A value that was contiguous only across logical slots is changed before Nosey Parker receives it.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    start = offset
    parts.append(text)
    offset += len(text)
    end = offset
    ranges.append({"slot": index, "start": start, "end": end})
    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
return "".join(parts), ranges
```

**Only single-slot Nosey Parker spans are mapped** — `privacy-service/proxy.py:154-165`

Any span crossing a slot boundary or inserted separator has no mapping and is discarded.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Presidio scans each unique slot independently** — `privacy-service/proxy.py:170-210`

No Presidio request contains adjacent slot fragments in their original logical order.

```python
unique_texts = list(dict.fromkeys(
    slot["text"]
    for slot in slots
))
...
for text in unique_texts:
    chunks = []
    for core_start in range(0, len(text), chunk_size):
        ...
async def scan(cache_key, chunk_text):
    async with semaphore:
        spans = await presidio_spans(chunk_text, "lt")
```

#### Reachability

Reachable whenever a caller or integration can create two content-bearing strings in the accepted structured input. Reachable at the public Responses parser boundary when the caller controls multiple ordered text parts. The public request parser accepts nested lists and dictionaries containing multiple strings, and the replacement pipeline preserves any slot for which no span is mapped.

- **Attacker:** Malicious or compromised CLI integration, plugin, skill, or direct API caller Malicious plugin, tool result, document integration, or client Caller or content source able to influence slot segmentation

- **Entry point:** privacy-service/proxy.py:97 structured input traversal POST /responses POST /responses payload.input

- **Source:** Sensitive value split between two or more string slots

- **Sink:** privacy-service/proxy.py:543 outbound JSON payload Remote upstream request httpx upstream request body

- **Outcome:** Detector evasion and upstream disclosure. Anonymization bypass Cleartext fragmented secret disclosure

Preconditions:
- Attacker can influence structured content boundaries.
- The sensitive value is represented across at least two semantically adjacent slots at a split not independently recognized.
- The upstream accepts the structured input shape.
- The fragments are not independently recognizable.
- The sensitive value is represented across at least two slots at a split not independently recognized.
- For cross-slot bypass, the sensitive value is split so each fragment evades independent recognition while the upstream receives the ordered fragments.
- For long-chunk bypass, a recognized entity crosses a 4000-character core boundary by more than the 256-character overlap.
- The client can split one logical value across two or more text slots.
- The sensitive pattern is divided so no individual slot matches
- The upstream or model can interpret the adjacent fragments

Existing controls:
- Per-slot Presidio detection
- Nosey Parker scan of a separated aggregate
- Dual Nosey Parker and Presidio detection
- Fixed 256-character Presidio overlap
- Fail-closed behavior on detector exceptions
- Fail-closed detector exception handling
- Per-slot Presidio overlap for long single-slot text

Limitations:
- Neither control canonicalizes content across slots.

**Logical slots separated before secret scanning** — `privacy-service/proxy.py:127-145`

A sensitive value divided between adjacent strings is no longer contiguous in the Nosey Parker corpus.

```python
for index, slot in enumerate(slots):
    text = slot["text"]
    ...
    ranges.append({"slot": index, "start": start, "end": end})
    separator = "\n\n"
    parts.append(separator)
    offset += len(separator)
return "".join(parts), ranges
```

**Cross-slot spans discarded** — `privacy-service/proxy.py:154-165`

Even a detector span crossing an inserted boundary is not applied to either contributing slot.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

**Only single-slot Nosey Parker spans are mapped** — `privacy-service/proxy.py:154-165`

Any span crossing a slot boundary or inserted separator has no mapping and is discarded.

```python
for span in secret_spans:
    for item in ranges:
        if (
            span["start"] >= item["start"]
            and span["end"] <= item["end"]
        ):
            mapped[item["slot"]].append({
                **span,
                "start": span["start"] - item["start"],
                "end": span["end"] - item["start"],
            })
            break
```

#### Severity

**High** — The source-backed boundary flaw can disclose a complete high-impact secret when structured fragments are not independently recognized. Exploitability for a particular secret and split point depends on external detector rules and accepted semantic adjacency. A split credential or identifier is disclosed in full to the upstream, but exploitation requires control over a multi-part representation and an upstream that reconstructs the ordered fragments. All components of a credential or PII value can cross the privacy boundary, producing high confidentiality impact. Exploitation requires control over multi-slot representation or a client that segments sensitive content at the relevant boundary.

Severity decreases when the accepted upstream schema cannot preserve semantic adjacency between caller-controlled slots or every fragment is independently detected; it increases when integrations routinely construct multipart sensitive values. Severity rises if supported clients routinely split one logical message across independently scanned text slots. Raise if untrusted repositories, attachments, or protocol adapters can reliably control content-item segmentation in production.

Impact assessment:
- **Level:** high
- **Rationale:** Credentials and other protected values can be transmitted in full. A complete credential or PII value can be reconstructed remotely. Credentials and personal identifiers can be reconstructed upstream.

Likelihood assessment:
- **Level:** high medium
- **Rationale:** Boundary shaping is deterministic and requires no detector failure. Requires a multi-part representation or deliberately fragmented content. Requires controlled or naturally occurring boundary placement but no detector malfunction.

#### Remediation

Build a canonical semantic stream for each logical message with a reversible offset map across adjacent content parts. Scan the seams without artificial separators and redact every contributing slot when a match intersects a boundary; reject fragmented forms that cannot be protected safely. Add boundary-fuzz tests while avoiding concatenation of semantically unrelated fields. Group adjacent text parts by their semantic message, scan a canonical concatenation with a reversible cross-slot offset map, and redact every touched slot. If safe reconstruction is unsupported, reject fragmented structures. Add split-at-every-character regression cases for credentials, email addresses, IBANs, and personal identifiers. Create a canonical logical-content stream with an offset map that can project a detected interval onto every contributing slot. Detect across real slot boundaries and replace all fragments of a cross-slot finding. Where concatenation semantics are ambiguous, scan bounded alternate canonical forms or reject suspicious fragmentation. Preserve logical message boundaries only after completing cross-boundary detection.

Tests:
- Split representative API keys, emails, phone numbers, IBANs, and URLs at every character position across adjacent input text nodes and assert no raw reconstruction reaches a mock upstream.
- Cover list elements and nested content objects separately.
- Verify unrelated fields are not accidentally concatenated into false-positive detector contexts.
- Split known API keys, emails, phone numbers, and identifiers across every possible two-slot boundary and assert no complete plaintext value is recoverable from outbound JSON.
- Inject a synthetic detector span crossing two slots and assert both intersecting fragments are redacted.
- Split each supported secret and PII pattern at every character boundary across two content items.
- Assert the captured outbound payload contains no reassemblable raw test secret.
- Split known email, API-key, account-number, and signed-URL fixtures at every character position across adjacent valid input items.
- Place long recognizer fixtures at every position around 4000-character boundaries and vary entity length beyond 256 characters.
- Assert that every contributing raw fragment is absent from the serialized upstream payload.
- Verify separate, semantically unrelated fields do not create false-positive cross-field matches.
- Split supported secret formats at every character boundary across adjacent input_text parts and assert no original fragments reach a capture upstream.
- Verify cross-slot matches redact all participating slots without corrupting protocol metadata.
- Split representative API keys, emails, phone numbers, IBANs, and private identifiers at every character position across two and three content items and assert no cleartext fragment set reaches a mock upstream.
- Add direct tests for a detector span crossing two mapped ranges and require both ranges to be replaced.
- Test mixed Unicode fragments to verify byte-to-character and cross-slot offset mapping together.
- Split fake API keys, emails, URLs, and IBANs at every character boundary.
- Verify unrelated metadata does not create composite false positives.

Preventive controls:
- Cross-slot seam scanning
- Canonical logical-message representation
- Boundary-fuzz regression suite
- Canonical representation before security scanning
- Cross-slot taint and offset tracking
- Fail-closed handling for noncanonical multipart content
- Canonical semantic normalization
- Cross-slot span mapping
- Boundary-aware canonicalization
- Reversible cross-slot offset mapping
- Adaptive overlap for boundary-touching detections
- Adversarial fragmentation regression suite
- Schema-aware logical-message normalization
- Cross-slot offset mapping
- Fail-closed rejection of unanalyzable multipart text
- Canonicalization before security analysis
- Cross-range interval representation
- Boundary-focused regression corpus
- Semantic-stream normalization

<a id="finding-3"></a>

### [3] Upstream output can inject restored secrets into protocol and tool fields

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | medium |
| Confidence rationale | Unrestricted restoration is directly proven, while execution or external disclosure through a downstream client is a deployment prerequisite not implemented in this repository. The global string replacement is direct and deterministic; only the downstream action needed for external exfiltration is deployment-dependent. Raw-stream replacement is explicit, the upstream necessarily sees created handles, and the repository's regression test confirms replacement across arbitrary streamed JSON chunks. Downstream execution remains a stated prerequisite, not a source claim. Restoration and outbound exemption are proven; the final round trip depends on the external client preserving call_id. |
| Category | context-blind-secret-restoration |
| CWE | CWE-74, CWE-345, CWE-200 |
| Affected lines | privacy-service/proxy.py:364-385, privacy-service/proxy.py:416-443, privacy-service/proxy.py:580-607, privacy-service/proxy.py:246-269, privacy-service/proxy.py:364-443, privacy-service/proxy.py:580-605, scripts/regression.ps1:165-202, privacy-service/proxy.py:246-269, privacy-service/proxy.py:580-605, scripts/regression.ps1:165-202, privacy-service/proxy.py:246-269, privacy-service/proxy.py:364-443, privacy-service/proxy.py:580-607, privacy-service/proxy.py:364-383, privacy-service/proxy.py:246-271, privacy-service/proxy.py:580-607, privacy-service/app.py:188-216, privacy-service/proxy.py:246-271, privacy-service/proxy.py:580-607, scripts/regression.ps1:165-203, privacy-service/proxy.py:26-39 |

#### Summary

The response restorer performs unrestricted replacement of every current-session placeholder across raw upstream SSE/JSON bytes before client parsing. Because the upstream sees those tokens, a prompt-influenced or compromised upstream can copy one into a command, URL, identifier, event field, or tool argument and cause the proxy to materialize the corresponding local-only secret in a machine-actionable destination. Predictable GP_\* strings are globally replaced throughout untrusted upstream response bytes, so a prompt-injected model can replay a visible token into text or tool arguments and have the proxy substitute the original secret locally. The upstream observes predictable GP_\* handles, and the proxy blindly replaces every matching occurrence across the complete raw response stream. A malicious or compromised model can place a handle in a tool-call argument, URL, command, or other active field so the proxy materializes the hidden plaintext secret before the downstream CLI processes it. The proxy replaces placeholders across the complete upstream byte stream. A malicious upstream can put a known GP_\* token into call_id, have it restored to the original, and receive the raw value later because outbound call_id is exempt from protection.

#### Root Cause

Placeholder authorization is based on byte equality within the current request rather than parsed response paths, destination semantics, and value provenance. Placeholders are treated as unauthenticated global string aliases rather than context-bound references, and the entire upstream protocol stream is rewritten without parsing. Possession of a visible placeholder is treated as authorization to de-tokenize it anywhere in an unparsed response, conflating passive display text with capability-bearing protocol fields. Restoration is raw substitution over an untrusted serialized response rather than schema-aware restoration into human-readable fields.

**Every token is replaced in arbitrary stream text** — `privacy-service/proxy.py:364-385`

The function has no knowledge of SSE events, JSON structure, user-visible text, or tool/control fields.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(token, escaped_original)
    return text
```

**All successful upstream bytes pass through the restorer** — `privacy-service/proxy.py:584-595`

There is no protocol parse or field allowlist before substitution.

```python
async for chunk in upstream.aiter_bytes():
    restored = feed_restore(chunk)
    if restored:
        yield restored
...
tail = finish_restore()
```

**Visible sequential placeholders map to originals** — `privacy-service/proxy.py:252-263`

The remote model receives the active placeholder strings while originals remain local.

```python
if original in session["value_to_token"]:
    token = session["value_to_token"][original]
else:
    entity = span["entity_type"].upper().replace(" ", "_")
    session["counters"][entity] += 1
    token = (
        f"GP_{entity}_"
        f"{session['counters'][entity]:04d}"
    )

    session["value_to_token"][original] = token
    session["token_to_value"][token] = original
```

**Restoration ignores protocol context** — `privacy-service/proxy.py:364-385`

Every matching token in raw decoded response data is replaced without parsing SSE events, JSON objects, or field roles.

```python
def make_stream_restorer(session):
    replacements = {
        token: json.dumps(
            original,
            ensure_ascii=False,
        )[1:-1]
        for token, original
        in session["token_to_value"].items()
    }

    tokens = list(replacements.keys())
    pending = ""
    decoder = codecs.getincrementaldecoder("utf-8")()

    def restore_complete(text):
        for token, escaped_original in replacements.items():
            text = text.replace(
                token,
                escaped_original,
            )

        return text
```

**Entire successful response stream is restored** — `privacy-service/proxy.py:580-605`

Structured model output reaches the local client only after context-free replacement.

```python
feed_restore, finish_restore = (
    make_stream_restorer(session)
)

async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)

            if restored:
                yield restored
```

**Predictable per-entity placeholder** — `privacy-service/proxy.py:255-263`

The upstream sees and can replay each generated token, while pre-existing literal token strings are not namespaced or escaped.

```python
session["counters"][entity] += 1
token = f"GP_{entity}_" f"{session['counters'][entity]:04d}"
session["token_to_value"][token] = original
```

**Unparsed global response replacement** — `privacy-service/proxy.py:364-385`

Every occurrence in every serialized response field is rehydrated without SSE/JSON parsing, field authorization, or destination context.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(token, escaped_original)
    return text
```

**Restored bytes are sent to the client** — `privacy-service/proxy.py:584-605`

The globally rewritten protocol stream reaches the local client, including any tool or resource control fields.

```python
async for chunk in upstream.aiter_bytes():
    restored = feed_restore(chunk)
    if restored:
        yield restored
...
return StreamingResponse(restored_stream(), ...)
```

**Sequential placeholder** — `privacy-service/proxy.py:255-263`

The upstream sees tokens whose values and namespace are predictable.

```python
session["counters"][entity] += 1
token = f"GP_{entity}_{session['counters'][entity]:04d}"
session["token_to_value"][token] = original
```

**Context-free restoration** — `privacy-service/proxy.py:378-385`

Replacement is not restricted by response event type, JSON path, token boundary, or permitted use.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(token, escaped_original)
    return text
```

**Context-free token expansion** — `privacy-service/proxy.py:378-385`

Every matching token is expanded without parsing the response event or checking the semantic destination field.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(
            token,
            escaped_original,
        )
    return text
```

**Restoration precedes client parsing** — `privacy-service/proxy.py:584-605`

Raw upstream bytes are globally rewritten before the local Responses client can distinguish assistant text from function or tool-control data.

```python
async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)
            if restored:
                yield restored
...
return StreamingResponse(
    restored_stream(),
    status_code=upstream.status_code,
    headers=forward_response_headers(upstream.headers),
)
```

**Tokens use a caller-collidable predictable namespace** — `privacy-service/proxy.py:252-263`

The request content is not checked for an identical literal token, and the upstream sees issued tokens in the anonymized input.

```python
if original in session["value_to_token"]:
    token = session["value_to_token"][original]
else:
    entity = span["entity_type"].upper().replace(" ", "_")
    session["counters"][entity] += 1
    token = (
        f"GP_{entity}_"
        f"{session['counters'][entity]:04d}"
    )

    session["value_to_token"][original] = token
    session["token_to_value"][token] = original
```

**Every matching response occurrence is restored** — `privacy-service/proxy.py:364-383`

Restoration is not bound to an issued occurrence, JSON path, response item type, or user-visible text context.

```python
def make_stream_restorer(session):
    replacements = {
        token: json.dumps(
            original,
            ensure_ascii=False,
        )[1:-1]
        for token, original
        in session["token_to_value"].items()
    }

    tokens = list(replacements.keys())
    pending = ""
    decoder = codecs.getincrementaldecoder("utf-8")()

    def restore_complete(text):
        for token, escaped_original in replacements.items():
            text = text.replace(
                token,
                escaped_original,
            )
```

**Predictable handles map to plaintext originals** — `privacy-service/proxy.py:252-263`

The upstream receives and can reuse a known token whose local mapping grants access to the original value.

```python
if original in session["value_to_token"]:
    token = session["value_to_token"][original]
else:
    entity = span["entity_type"].upper().replace(" ", "_")
    session["counters"][entity] += 1
    token = f"GP_{entity}_{session['counters'][entity]:04d}"
    session["value_to_token"][original] = token
    session["token_to_value"][token] = original
```

**Every occurrence is restored without response-context validation** — `privacy-service/proxy.py:364-385`

JSON escaping prevents syntax breakout but no parser restricts substitution to passive assistant text.

```python
def make_stream_restorer(session):
    replacements = {
        token: json.dumps(original, ensure_ascii=False)[1:-1]
        for token, original in session["token_to_value"].items()
    }
    ...
    def restore_complete(text):
        for token, escaped_original in replacements.items():
            text = text.replace(token, escaped_original)
        return text
```

**The rewritten bytes are streamed directly to the client** — `privacy-service/proxy.py:580-607`

All successful upstream protocol bytes, including structured active fields, pass through the same restoration transform.

```python
feed_restore, finish_restore = make_stream_restorer(session)
async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)
            if restored:
                yield restored
        tail = finish_restore()
        if tail:
            yield tail
    finally:
        ...
return StreamingResponse(restored_stream(), status_code=upstream.status_code, headers=forward_response_headers(upstream.headers))
```

**Every response context is rewritten** — `privacy-service/proxy.py:378-385`

The restorer has no SSE event, JSON path, field type, or destination-grammar awareness.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(token, escaped_original)
    return text
```

**Protocol identifiers are not protected outbound** — `privacy-service/proxy.py:26-39`

A secret restored into call_id is preserved on a later protected request.

```python
SKIP_STRING_KEYS = {
 "type", "role", "id", "call_id", "name", "namespace",
 "status", "model", "image_url", "audio_url", "encrypted_content",
}
```

**Successful stream is wholly restored** — `privacy-service/proxy.py:584-595`

The full serialized upstream response passes through raw replacement.

```python
async for chunk in upstream.aiter_bytes():
    restored = feed_restore(chunk)
    if restored:
        yield restored

tail = finish_restore()
```

#### Validation

Static validation establishes that current-session placeholders are visible upstream and globally expanded before the client distinguishes display text from machine-actionable fields. Actual disclosure or execution still depends on the downstream client consuming the affected field. Any matching token emitted by the upstream is replaced everywhere. Literal caller-supplied GP strings can collide with issued tokens, and an upstream model that sees an issued token can replay it in another response context. The response restorer performs unrestricted textual substitution before the downstream client parses the protocol. The model can observe each handle in the request and emit it in any response field. Upstream knows GP tokens, can emit one as call_id, and the proxy rewrites it to the original; a normal tool-result round trip then sends that exempt call_id raw.

Validation method: Manual review of incremental decoding, token-boundary handling, JSON escaping, and response consumption boundary. Independent baseline discovery, focused follow-up validation, and parent source revalidation. Two-request static dataflow

- **Status:** validated-with-prerequisite
- **Disposition:** report

**Every token is replaced in arbitrary stream text** — `privacy-service/proxy.py:364-385`

The function has no knowledge of SSE events, JSON structure, user-visible text, or tool/control fields.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(token, escaped_original)
    return text
```

**All successful upstream bytes pass through the restorer** — `privacy-service/proxy.py:584-595`

There is no protocol parse or field allowlist before substitution.

```python
async for chunk in upstream.aiter_bytes():
    restored = feed_restore(chunk)
    if restored:
        yield restored
...
tail = finish_restore()
```

**Visible sequential placeholders map to originals** — `privacy-service/proxy.py:252-263`

The remote model receives the active placeholder strings while originals remain local.

```python
if original in session["value_to_token"]:
    token = session["value_to_token"][original]
else:
    entity = span["entity_type"].upper().replace(" ", "_")
    session["counters"][entity] += 1
    token = (
        f"GP_{entity}_"
        f"{session['counters'][entity]:04d}"
    )

    session["value_to_token"][original] = token
    session["token_to_value"][token] = original
```

**Restoration ignores protocol context** — `privacy-service/proxy.py:364-385`

Every matching token in raw decoded response data is replaced without parsing SSE events, JSON objects, or field roles.

```python
def make_stream_restorer(session):
    replacements = {
        token: json.dumps(
            original,
            ensure_ascii=False,
        )[1:-1]
        for token, original
        in session["token_to_value"].items()
    }

    tokens = list(replacements.keys())
    pending = ""
    decoder = codecs.getincrementaldecoder("utf-8")()

    def restore_complete(text):
        for token, escaped_original in replacements.items():
            text = text.replace(
                token,
                escaped_original,
            )

        return text
```

**Entire successful response stream is restored** — `privacy-service/proxy.py:580-605`

Structured model output reaches the local client only after context-free replacement.

```python
feed_restore, finish_restore = (
    make_stream_restorer(session)
)

async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)

            if restored:
                yield restored
```

**Predictable per-entity placeholder** — `privacy-service/proxy.py:255-263`

The upstream sees and can replay each generated token, while pre-existing literal token strings are not namespaced or escaped.

```python
session["counters"][entity] += 1
token = f"GP_{entity}_" f"{session['counters'][entity]:04d}"
session["token_to_value"][token] = original
```

**Unparsed global response replacement** — `privacy-service/proxy.py:364-385`

Every occurrence in every serialized response field is rehydrated without SSE/JSON parsing, field authorization, or destination context.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(token, escaped_original)
    return text
```

**Restored bytes are sent to the client** — `privacy-service/proxy.py:584-605`

The globally rewritten protocol stream reaches the local client, including any tool or resource control fields.

```python
async for chunk in upstream.aiter_bytes():
    restored = feed_restore(chunk)
    if restored:
        yield restored
...
return StreamingResponse(restored_stream(), ...)
```

**Context-free token expansion** — `privacy-service/proxy.py:378-385`

Every matching token is expanded without parsing the response event or checking the semantic destination field.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(
            token,
            escaped_original,
        )
    return text
```

**Restoration precedes client parsing** — `privacy-service/proxy.py:584-605`

Raw upstream bytes are globally rewritten before the local Responses client can distinguish assistant text from function or tool-control data.

```python
async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)
            if restored:
                yield restored
...
return StreamingResponse(
    restored_stream(),
    status_code=upstream.status_code,
    headers=forward_response_headers(upstream.headers),
)
```

**Predictable handles map to plaintext originals** — `privacy-service/proxy.py:252-263`

The upstream receives and can reuse a known token whose local mapping grants access to the original value.

```python
if original in session["value_to_token"]:
    token = session["value_to_token"][original]
else:
    entity = span["entity_type"].upper().replace(" ", "_")
    session["counters"][entity] += 1
    token = f"GP_{entity}_{session['counters'][entity]:04d}"
    session["value_to_token"][original] = token
    session["token_to_value"][token] = original
```

**Every occurrence is restored without response-context validation** — `privacy-service/proxy.py:364-385`

JSON escaping prevents syntax breakout but no parser restricts substitution to passive assistant text.

```python
def make_stream_restorer(session):
    replacements = {
        token: json.dumps(original, ensure_ascii=False)[1:-1]
        for token, original in session["token_to_value"].items()
    }
    ...
    def restore_complete(text):
        for token, escaped_original in replacements.items():
            text = text.replace(token, escaped_original)
        return text
```

**The rewritten bytes are streamed directly to the client** — `privacy-service/proxy.py:580-607`

All successful upstream protocol bytes, including structured active fields, pass through the same restoration transform.

```python
feed_restore, finish_restore = make_stream_restorer(session)
async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)
            if restored:
                yield restored
        tail = finish_restore()
        if tail:
            yield tail
    finally:
        ...
return StreamingResponse(restored_stream(), status_code=upstream.status_code, headers=forward_response_headers(upstream.headers))
```

**Every response context is rewritten** — `privacy-service/proxy.py:378-385`

The restorer has no SSE event, JSON path, field type, or destination-grammar awareness.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(token, escaped_original)
    return text
```

**Protocol identifiers are not protected outbound** — `privacy-service/proxy.py:26-39`

A secret restored into call_id is preserved on a later protected request.

```python
SKIP_STRING_KEYS = {
 "type", "role", "id", "call_id", "name", "namespace",
 "status", "model", "image_url", "audio_url", "encrypted_content",
}
```

**Successful stream is wholly restored** — `privacy-service/proxy.py:584-595`

The full serialized upstream response passes through raw replacement.

```python
async for chunk in upstream.aiter_bytes():
    restored = feed_restore(chunk)
    if restored:
        yield restored

tail = finish_restore()
```

Assertions:
- The upstream sees generated placeholder tokens in the protected request.
- Any literal token in a successful response stream is restored regardless of field context.
- The upstream sees active placeholder strings in the protected request.
- No JSON, SSE, event-type, or field allowlist exists before replacement.
- Repository regression tests assert cross-chunk replacement but do not constrain restoration to user-visible text.
- The upstream observes every generated placeholder in the protected request.
- The replacement applies equally to display text, function-call arguments, URLs, commands, filenames, and protocol metadata.
- Restoration runs on raw decoded bytes.
- Tool-call and URL contexts are not excluded.
- Generated placeholders are stored with their originals and transmitted in protected request content.
- The upstream controls response bytes and can repeat a visible placeholder in any string field.
- The restorer replaces all current-session occurrences before returning the stream.
- Token values are predictable and visible in the outbound request.
- No collision check or authenticated framing exists.
- Restoration uses unrestricted text.replace over the full response stream.
- The upstream learns every placeholder used in the anonymized request.
- Restoration is raw text replacement, not schema-aware event processing.
- Tool definitions are part of the documented protocol handling, so active downstream fields are in scope.
- The client receives restored bytes.

Counterevidence and remaining uncertainty:
- Originals are JSON-escaped, reducing direct quote/newline breakout inside JSON strings.
- The proxy does not itself execute tool calls.
- Client approval and sandbox controls can prevent a restored tool argument from reaching an external sink.
- JSON escaping reduces accidental syntax corruption in ordinary string contexts.
- Per-request sessions are removed when the stream closes, limiting replay lifetime.
- Upstream error responses are returned without restoration.
- Downstream approval or sandbox controls may prevent a restored tool action from executing.
- The upstream is not directly sent the restored value by this code.
- Each /responses request uses a fresh session and normally deletes it when streaming ends.
- Downstream approvals or disabled automatic resource fetching may interrupt exploit completion.
- Original values are JSON-escaped, limiting direct JSON-string breakout.
- Per-response sessions are deleted when streaming ends.
- Chunk-prefix handling correctly preserves exact tokens.
- Responses sessions are request-scoped and removed at stream completion, preventing stale cross-session restoration.
- The original is JSON-escaped once, which preserves ordinary outer JSON strings but does not restrict semantic destination or nested grammar.
- Actual exfiltration depends on downstream consumption or execution of the affected field.
- The original secret is not revealed to the upstream by substitution alone.
- The stream restorer correctly handles ordinary UTF-8 and chunk boundaries.
- External exfiltration depends on later execution or transmission by the client.
- Originals are JSON-string escaped, preventing direct quote/newline syntax breakout.
- HTTP error responses are returned without restoration and request sessions are removed after streaming.
- Actual external exfiltration requires a downstream tool action and may be constrained by client approval or sandbox policy.
- Originals are JSON-escaped.
- Downstream client implementation is outside the repo.
- Session state is deleted after streaming.

Limitations:
- Downstream Codex/Claude tool execution policy was not part of the supplied source.
- The downstream Codex execution and approval policy is outside the reviewed repository.
- The reviewed repository does not implement the downstream client's tool execution or URL-fetch policy.
- Automatic tool execution and approval behavior are client-dependent.
- The downstream Codex client implementation and approval policy are outside the scanned directory.
- No live Codex tool-execution path was exercised.
- External client round-trip behavior was not executed.

#### Dataflow

Upstream-chosen token occurrence -\> raw stream replacement -\> downstream structured field containing original secret. Detected local secret -\> visible GP token upstream -\> model emits token in arbitrary response or tool arguments -\> global local replacement -\> client consumes real secret in attacker-chosen context. Detected secret -\> GP_\* handle sent upstream -\> upstream emits handle in active response field -\> raw stream replacement -\> downstream receives plaintext in that active field.

Attack steps:
- Observe a placeholder token in the protected prompt.
- Return the token in a tool argument, identifier, key, or other structured response field.
- The proxy replaces it with the locally stored escaped original.
- The downstream client logs, consumes, or executes the altered field.

- **Source:** External upstream response stream Untrusted upstream response bytes Upstream-controlled response bytes containing a handle observed in the request

- **Sink:** Local client protocol/tool consumer Restored client output or downstream tool argument Downstream CLI parser and potential tool/action handler

- **Outcome:** A local secret is injected into an upstream-selected context. Secret injection, unintended disclosure, or misuse Secret is materialized in a command, URL, file, environment value, or tool argument

Transformations:
- Incremental UTF-8 decoding
- literal token replacement
- re-encoding
- Sensitive value is mapped to a GP_\* token.
- The token is included in the protected upstream request.
- The upstream emits the token inside a response field.
- The proxy replaces the token with a JSON-escaped original across the raw stream.
- Predictable placeholder generation
- Global byte-stream replacement
- Placeholder assignment
- upstream generation
- incremental UTF-8 decoding
- global text replacement
- stream delivery

**Every token is replaced in arbitrary stream text** — `privacy-service/proxy.py:364-385`

The function has no knowledge of SSE events, JSON structure, user-visible text, or tool/control fields.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(token, escaped_original)
    return text
```

**All successful upstream bytes pass through the restorer** — `privacy-service/proxy.py:584-595`

There is no protocol parse or field allowlist before substitution.

```python
async for chunk in upstream.aiter_bytes():
    restored = feed_restore(chunk)
    if restored:
        yield restored
...
tail = finish_restore()
```

**Context-free token expansion** — `privacy-service/proxy.py:378-385`

Every matching token is expanded without parsing the response event or checking the semantic destination field.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(
            token,
            escaped_original,
        )
    return text
```

**Restoration precedes client parsing** — `privacy-service/proxy.py:584-605`

Raw upstream bytes are globally rewritten before the local Responses client can distinguish assistant text from function or tool-control data.

```python
async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)
            if restored:
                yield restored
...
return StreamingResponse(
    restored_stream(),
    status_code=upstream.status_code,
    headers=forward_response_headers(upstream.headers),
)
```

**Tokens use a caller-collidable predictable namespace** — `privacy-service/proxy.py:252-263`

The request content is not checked for an identical literal token, and the upstream sees issued tokens in the anonymized input.

```python
if original in session["value_to_token"]:
    token = session["value_to_token"][original]
else:
    entity = span["entity_type"].upper().replace(" ", "_")
    session["counters"][entity] += 1
    token = (
        f"GP_{entity}_"
        f"{session['counters'][entity]:04d}"
    )

    session["value_to_token"][original] = token
    session["token_to_value"][token] = original
```

**Every matching response occurrence is restored** — `privacy-service/proxy.py:364-383`

Restoration is not bound to an issued occurrence, JSON path, response item type, or user-visible text context.

```python
def make_stream_restorer(session):
    replacements = {
        token: json.dumps(
            original,
            ensure_ascii=False,
        )[1:-1]
        for token, original
        in session["token_to_value"].items()
    }

    tokens = list(replacements.keys())
    pending = ""
    decoder = codecs.getincrementaldecoder("utf-8")()

    def restore_complete(text):
        for token, escaped_original in replacements.items():
            text = text.replace(
                token,
                escaped_original,
            )
```

**Predictable handles map to plaintext originals** — `privacy-service/proxy.py:252-263`

The upstream receives and can reuse a known token whose local mapping grants access to the original value.

```python
if original in session["value_to_token"]:
    token = session["value_to_token"][original]
else:
    entity = span["entity_type"].upper().replace(" ", "_")
    session["counters"][entity] += 1
    token = f"GP_{entity}_{session['counters'][entity]:04d}"
    session["value_to_token"][original] = token
    session["token_to_value"][token] = original
```

**Every occurrence is restored without response-context validation** — `privacy-service/proxy.py:364-385`

JSON escaping prevents syntax breakout but no parser restricts substitution to passive assistant text.

```python
def make_stream_restorer(session):
    replacements = {
        token: json.dumps(original, ensure_ascii=False)[1:-1]
        for token, original in session["token_to_value"].items()
    }
    ...
    def restore_complete(text):
        for token, escaped_original in replacements.items():
            text = text.replace(token, escaped_original)
        return text
```

**The rewritten bytes are streamed directly to the client** — `privacy-service/proxy.py:580-607`

All successful upstream protocol bytes, including structured active fields, pass through the same restoration transform.

```python
feed_restore, finish_restore = make_stream_restorer(session)
async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)
            if restored:
                yield restored
        tail = finish_restore()
        if tail:
            yield tail
    finally:
        ...
return StreamingResponse(restored_stream(), status_code=upstream.status_code, headers=forward_response_headers(upstream.headers))
```

#### Reachability

The replacement primitive is reached for every successful upstream response; security impact requires a downstream consumer that treats the chosen field as meaningful. Reachable when repository or document prompt injection influences model output and the client consumes a restored field. A successful upstream response can contain the exact observed handle in any streamed JSON/SSE field; the proxy applies no field-level authorization before substitution.

- **Attacker:** Malicious or prompt-influenced upstream model/provider Prompt-injected content or malicious upstream Malicious, compromised, or prompt-influenced upstream response producer

- **Entry point:** Successful streamed /responses reply Anonymized request containing an issued GP token Successful upstream /responses stream

- **Source:** Known GP_\* placeholder

- **Sink:** Client control or tool field after local restoration Client-visible text, generated code, or tool arguments Restored downstream active field

- **Outcome:** Potential local tool manipulation or secondary secret disclosure. Original secret appears in an attacker-selected local context Potential local secret misuse or exfiltration

Preconditions:
- A successful upstream response and a security-relevant downstream field.
- At least one sensitive value was tokenized in the current request.
- A successful upstream response contains the active token in a security-relevant downstream field.
- The upstream emits a literal generated token.
- The downstream client consumes the altered non-text field.
- The request contains a value detected and tokenized by the proxy.
- The upstream response includes that visible token in a machine-actionable field.
- The client parses or executes the restored field with a disclosure-capable tool or operation.
- At least one secret is detected.
- The model outputs the token.
- For external exfiltration, the client executes or transmits the restored field.
- At least one sensitive input created a mapping
- The response contains that handle
- The downstream honors the active field for end impact

Existing controls:
- JSON escaping of originals
- Possible downstream user approval and sandboxing
- Fresh per-request session
- Normal session cleanup after stream finalization
- Possible downstream approval or disabled automatic resource fetching
- Per-request session isolation
- JSON escaping for direct outer JSON string substitution
- Potential downstream tool approval and sandbox controls outside this repository
- Per-request session lifetime
- JSON string escaping
- Downstream sandbox and approval policy

Blind spots:
- Downstream client tool execution, URL fetching, logging, and approval policy are outside the reviewed repository.

Limitations:
- No downstream client runtime was exercised.
- These controls reduce syntax corruption or tool execution but do not stop semantic secret insertion.

**Context-free token expansion** — `privacy-service/proxy.py:378-385`

Every matching token is expanded without parsing the response event or checking the semantic destination field.

```python
def restore_complete(text):
    for token, escaped_original in replacements.items():
        text = text.replace(
            token,
            escaped_original,
        )
    return text
```

**Restoration precedes client parsing** — `privacy-service/proxy.py:584-605`

Raw upstream bytes are globally rewritten before the local Responses client can distinguish assistant text from function or tool-control data.

```python
async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)
            if restored:
                yield restored
...
return StreamingResponse(
    restored_stream(),
    status_code=upstream.status_code,
    headers=forward_response_headers(upstream.headers),
)
```

**The rewritten bytes are streamed directly to the client** — `privacy-service/proxy.py:580-607`

All successful upstream protocol bytes, including structured active fields, pass through the same restoration transform.

```python
feed_restore, finish_restore = make_stream_restorer(session)
async def restored_stream():
    try:
        async for chunk in upstream.aiter_bytes():
            restored = feed_restore(chunk)
            if restored:
                yield restored
        tail = finish_restore()
        if tail:
            yield tail
    finally:
        ...
return StreamingResponse(restored_stream(), status_code=upstream.status_code, headers=forward_response_headers(upstream.headers))
```

#### Severity

**Medium** — The source-backed primitive can place a local secret into an upstream-selected downstream field; high impact requires a client to consume, log, or execute that field, and downstream approval policies may mitigate exploitation. A successful downstream action can disclose or misuse a high-impact local secret, but practical exfiltration requires model-output influence and a client that executes or transmits the restored field. The primitive can expose or misuse high-value secrets through local capabilities. It requires an upstream-controlled response plus downstream acceptance or execution of an active field, so likelihood is medium under the documented agent-client use.

Severity becomes high when the integrated client automatically executes network-capable tool calls or exports structured response fields without approval. Severity rises when downstream tool actions are auto-approved or network-capable. Raise if downstream clients automatically execute network-capable tool calls without approval. Lower if protocol parsing proves restoration is confined to passive human-visible text.

Impact assessment:
- **Level:** high
- **Rationale:** A restored credential can reach a local tool or log chosen by the upstream. A local credential can be placed into commands, URLs, files, or logs without the upstream knowing its value. A secret hidden from the model can be inserted into a local network or execution capability.

Likelihood assessment:
- **Level:** medium
- **Rationale:** The primitive is deterministic, but external impact depends on downstream client behavior. Model output is routinely influenced by repository content, but dangerous downstream use may require approval. The primitive is deterministic; end impact depends on response control and downstream approval/execution.

#### Remediation

Parse the upstream SSE protocol and each JSON event incrementally, then restore only whole placeholders in narrowly allowlisted user-visible text fields. Never restore event names, IDs, keys, status values, tool names or arguments, URLs, filenames, commands, code, media references, encrypted content, or framing unless a separate destination-specific policy explicitly authorizes it. Use a high-entropy per-request namespace proven absent from the outbound payload, detect literal-token collisions, perform one non-recursive substitution pass, and resolve any legitimate tool secret through a scoped local capability after policy and user approval. Parse the upstream response protocol and restore placeholders only in explicitly safe user-visible text paths, never in tool-call arguments, URLs, executable content, identifiers, or control fields. Use a random per-session authenticated namespace, reject request collisions, track issued occurrences, and require exact framed-token parsing. Parse the upstream Responses/SSE protocol and restore placeholders only in explicitly approved passive human-visible assistant-content fields. Never restore inside tool names, tool arguments, URLs, commands, identifiers, or structured control fields. If tools require a secret, resolve it just-in-time in a trusted local tool layer with per-argument policy and explicit approval. Randomizing handles alone is insufficient because the upstream observes them. Parse SSE and JSON structurally and restore only allowlisted human-readable response fields. Never restore identifiers, URLs, encrypted data, tool definitions, or tool-call arguments; encode for the actual destination grammar.

Tests:
- Return known placeholders in text deltas, IDs, keys, status values, and tool arguments; assert restoration occurs only in the approved text fields.
- Test token splits across transport chunks after protocol-aware parsing.
- Verify malformed SSE/JSON fails closed without falling back to raw global replacement.
- Place an active placeholder in function arguments, nested JSON, URLs, IDs, and SSE metadata and assert it is not restored.
- Verify restoration still works across chunk boundaries only for allowlisted user-visible text deltas.
- Assert tool-capability resolution requires explicit policy and approval.
- Have a mock upstream place every current token in tool arguments, URLs, commands, identifiers, and display text; assert plaintext is restored only in explicitly safe display fields.
- Include a literal GP_\* string in input alongside a detected secret and verify it cannot collide with generated tokens.
- Test token prefixes, chunk splits, JSON escaping, malformed SSE, and stream cancellation.
- Emit known tokens in tool arguments, URLs, IDs, JSON keys, code, and display text; restore only the approved display occurrence.
- Test literal namespace collisions and token-looking originals.
- A placeholder in assistant display text is restored.
- The same placeholder in function-call arguments, URLs, commands, identifiers, and event metadata remains opaque or causes rejection.
- Nested serialized arguments containing quotes, backslashes, and control characters remain valid and never receive a secret.
- A model-generated token-like literal that lacks authorized response-path provenance is not expanded.
- Place literal GP_\* text and a real detected secret in one request and assert only the issued occurrence can be restored.
- Emit an issued token in tool-call arguments, URLs, identifiers, and code fields and assert those fields are rejected or left non-secret.
- Verify safe user-visible text still restores across arbitrary UTF-8 stream chunks.
- Feed a mock upstream stream containing a valid handle in assistant text, a tool argument, URL, command, and identifier; restore only the approved passive-text occurrence.
- Split handles across arbitrary stream chunks and verify the context policy still applies after event parsing.
- Require explicit local policy approval before any plaintext mapping can enter an outbound or executable tool parameter.
- Emit placeholders in call_id, id, URL, and tool arguments and assert they remain opaque.
- Round-trip a fake tool call and verify no original appears upstream.

Preventive controls:
- Schema-aware response transformation
- Field-level restoration allowlist
- Downstream tool-call policy tests
- Protocol-aware SSE and JSON parsing
- Taint tracking from placeholder to downstream sink
- Scoped local capability resolution for tools
- Structured protocol parser
- High-entropy collision-free token namespace
- Destination-aware secret resolution
- Typed response parsing
- Context-bound restoration tokens
- Action-field denylist
- Schema-aware response parsing
- Display-only restoration allowlist
- Taint tracking for restored values
- High-entropy request-scoped token namespace to reduce accidental collisions
- Protocol-aware response parser
- Context allowlist for restoration
- Authenticated per-session placeholder framing
- Collision detection
- Provenance-bound detokenization
- Separate passive text rendering from active tool semantics
- Schema-aware SSE parsing
- Response restoration allowlist
- Protocol identifier immutability

<a id="finding-4"></a>

### [4] Unauthenticated local proxy identity permits OAuth credential capture

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | The installed provider, shallow health check, and Authorization forwarding are all explicit in source. The source directly configures HTTP loopback with requires_openai_auth and provides no endpoint identity. Exact Codex token behavior is inferred from the named configuration semantics and repository integration documentation. |
| Category | origin-authentication-failure |
| CWE | CWE-346, CWE-300 |
| Affected lines | scripts/common.ps1:246-261, scripts/common.ps1:514-520, scripts/install.ps1:8-18, scripts/codex-with-privacy.ps1:25-41, scripts/common.ps1:53-55, scripts/common.ps1:208-229, scripts/common.ps1:514-525, privacy-service/proxy.py:81-86, docker-compose.yml:48-51 |

#### Summary

Codex is configured to send authentication over plain loopback HTTP, while readiness checks trust any HTTP 200; a local process that owns the port can impersonate the proxy and receive OAuth headers and prompts. Installation configures Codex to send OpenAI authentication to a plain HTTP loopback base URL, but neither the provider nor health checks authenticate the listening process. While the genuine stack is stopped, another local principal can bind the configured port and receive the victim's Authorization header when Codex is launched.

#### Root Cause

Port ownership plus an HTTP status code is treated as service identity; no shared secret, authenticated IPC, or server identity binding protects the local hop. A reusable upstream bearer credential is sent through a local TCP endpoint authenticated only by address and port ownership.

**Health check authenticates only status** — `scripts/common.ps1:246-261`

Any listener returning 200 is treated as the intended privacy service.

```powershell
function Test-HttpOk {
    ...
    $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 5
    return $response.StatusCode -eq 200
}
function Test-PrivacyStackHealthy {
    return ((Test-HttpOk -Uri "$Script:AnalyzerBaseUrl/health") -and (Test-HttpOk -Uri "$Script:ProxyBaseUrl/health"))
}
```

**OAuth-enabled plaintext provider** — `scripts/common.ps1:514-520`

The client will deliver its OpenAI authentication to the configured loopback listener.

```powershell
[model_providers.$providerId]
name = "$providerName"
base_url = "$Script:ProxyBaseUrl"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
```

**Codex provider sends auth to a plain HTTP local URL** — `scripts/common.ps1:514-521`

The credential-bearing provider is bound to a generic TCP URL with no server identity configuration.

```powershell
$providerBlock = @"
[model_providers.$providerId]
name = "$providerName"
base_url = "$Script:ProxyBaseUrl"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
"@
```

**Provider URL is unauthenticated HTTP** — `scripts/common.ps1:53-55`

No TLS, named-pipe ACL, per-install secret, or certificate/public-key check authenticates the listener.

```powershell
$Script:ProjectConfig = Get-ProjectConfig
$Script:ProxyBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["PROXY_PORT"]
$Script:AnalyzerBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["ANALYZER_PORT"]
```

**Authorization is retained for forwarding** — `privacy-service/proxy.py:81-86`

Authorization is not excluded, consistent with the configured provider delivering the bearer credential to whichever process owns the port.

```python
def forward_request_headers(request: Request):
    return {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS
    }
```

#### Validation

When the genuine listener is absent, another local process can satisfy readiness and receive later credential-bearing requests. The provider persists after installation, uses HTTP, and has no local peer authentication. A free high-numbered loopback port can be owned by a different local process.

Validation method: Offline configuration and call-path review Independent backward review of provider setup and credential forwarding followed by parent source revalidation.

- **Status:** confirmed
- **Disposition:** report

**Codex provider sends auth to a plain HTTP local URL** — `scripts/common.ps1:514-521`

The credential-bearing provider is bound to a generic TCP URL with no server identity configuration.

```powershell
$providerBlock = @"
[model_providers.$providerId]
name = "$providerName"
base_url = "$Script:ProxyBaseUrl"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
"@
```

**Provider URL is unauthenticated HTTP** — `scripts/common.ps1:53-55`

No TLS, named-pipe ACL, per-install secret, or certificate/public-key check authenticates the listener.

```powershell
$Script:ProjectConfig = Get-ProjectConfig
$Script:ProxyBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["PROXY_PORT"]
$Script:AnalyzerBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["ANALYZER_PORT"]
```

**Authorization is retained for forwarding** — `privacy-service/proxy.py:81-86`

Authorization is not excluded, consistent with the configured provider delivering the bearer credential to whichever process owns the port.

```python
def forward_request_headers(request: Request):
    return {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS
    }
```

Assertions:
- The base URL is HTTP loopback.
- requires_openai_auth is true.
- No local authentication secret is configured.
- The provider requires OpenAI authentication.
- Its base URL is plain HTTP and defaults to loopback.
- The proxy forwards Authorization.
- No client or server authentication proves the listener is the intended container.

Counterevidence and remaining uncertainty:
- The default bind excludes remote network peers.
- A running legitimate container already owns the port.
- A remote LAN attacker cannot reach the default loopback address.
- A second process cannot bind the port while the genuine container owns it.
- The strongest boundary crossing is another locally isolated principal; same-user malware may already have other credential access.

Limitations:
- Port ACL behavior for multiple Windows users was not runtime-tested.
- Exact bearer reuse scope and host-specific loopback port ownership were not runtime-tested.

#### Dataflow

Local attacker listener -\> spoofed /health 200 -\> provider remains active -\> Codex /responses with OAuth -\> attacker. Persistent provider config -\> attacker binds free loopback port -\> user launches Codex -\> Codex sends Authorization to configured HTTP URL -\> attacker-controlled listener captures it.

- **Source:** Codex OAuth Authorization header Codex/OpenAI Authorization header

- **Sink:** Impersonating loopback process Process owning the configured loopback TCP port

- **Outcome:** Credential and prompt theft Bearer credential disclosure

Transformations:
- Provider selection
- HTTP request construction
- local TCP delivery

**Codex provider sends auth to a plain HTTP local URL** — `scripts/common.ps1:514-521`

The credential-bearing provider is bound to a generic TCP URL with no server identity configuration.

```powershell
$providerBlock = @"
[model_providers.$providerId]
name = "$providerName"
base_url = "$Script:ProxyBaseUrl"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
"@
```

**Provider URL is unauthenticated HTTP** — `scripts/common.ps1:53-55`

No TLS, named-pipe ACL, per-install secret, or certificate/public-key check authenticates the listener.

```powershell
$Script:ProjectConfig = Get-ProjectConfig
$Script:ProxyBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["PROXY_PORT"]
$Script:AnalyzerBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["ANALYZER_PORT"]
```

**Authorization is retained for forwarding** — `privacy-service/proxy.py:81-86`

Authorization is not excluded, consistent with the configured provider delivering the bearer credential to whichever process owns the port.

```python
def forward_request_headers(request: Request):
    return {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS
    }
```

#### Reachability

Reachable while the genuine stack is stopped or before startup. The default port is unprivileged and the provider configuration remains installed even when the proxy stack is stopped.

- **Attacker:** Untrusted local process Separate local process able to bind a free loopback port

- **Entry point:** Configured 127.0.0.1 proxy port Configured provider base URL

- **Source:** Victim Codex request

- **Sink:** Impersonating local HTTP listener

- **Outcome:** Credential capture

Preconditions:
- Attacker can bind the port before the legitimate service.
- Genuine proxy is not holding the port
- Victim launches Codex with the installed provider
- Attacker can bind the configured local port

Existing controls:
- Default loopback address
- Port exclusivity while the genuine service runs
- Documented start and health workflows

Limitations:
- Health checks accept an arbitrary 200 response and do not authenticate service identity.

**Provider URL is unauthenticated HTTP** — `scripts/common.ps1:53-55`

No TLS, named-pipe ACL, per-install secret, or certificate/public-key check authenticates the listener.

```powershell
$Script:ProjectConfig = Get-ProjectConfig
$Script:ProxyBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["PROXY_PORT"]
$Script:AnalyzerBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["ANALYZER_PORT"]
```

#### Severity

**Medium** — Credential theft has high impact, but the attacker must already execute locally and claim the configured port, so the localhost boundary warrants a downgrade. Credential theft has high impact, but the path is localhost-only by default and requires a separate local principal, a free configured port, and the user to launch Codex while the genuine service is absent or impersonated.

Raise if multi-user hosts routinely run the proxy, if clients launch without a verified stack, or if the configured provider address is reachable by less-trusted network principals.

Impact assessment:
- **Level:** high
- **Rationale:** OAuth credentials and all proxied prompts can be captured. A reusable bearer credential may allow unauthorized account/API actions within its scope.

Likelihood assessment:
- **Level:** medium low
- **Rationale:** Requires local code execution and a port-ownership opportunity. The path is local and timing/state constrained, and normal workflow starts and checks the stack first.

#### Remediation

Authenticate the local hop with a high-entropy per-install secret protected by user ACLs or use OS-authenticated IPC. Verify service identity before activation, configure Codex only after authenticated startup, and roll back provider changes on failure. Use an OS-authenticated local transport such as a named pipe or Unix-domain socket with user ACLs. If TCP is unavoidable, use mutually authenticated TLS or a per-installation client/server credential and pin the proxy identity. Do not send the reusable upstream bearer token to an unauthenticated listener; authenticate local clients and obtain or forward upstream credentials only inside the verified proxy.

Tests:
- Start a fake 200-response listener and verify install/wrapper refuse it.
- Verify missing or incorrect local authentication fails before OAuth-bearing traffic is accepted.
- Start an impostor listener on the configured port and verify Codex refuses to send Authorization without the installed proxy identity.
- Verify another local account cannot connect to or bind the authenticated transport.
- Ensure health and readiness checks validate the same cryptographic instance identity used by the client.

Preventive controls:
- Authenticated local channel
- Provider activation rollback
- OS ACL-protected IPC
- Mutual endpoint authentication
- Credential audience separation

<a id="finding-5"></a>

### [5] Section-blind TOML rewriting can leave Codex outside the privacy proxy

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | medium |
| Confidence rationale | The regex behavior is explicit, but the repository does not include a current user config demonstrating the prerequisite shape. |
| Category | configuration-scope-confusion |
| CWE | CWE-20 |
| Affected lines | scripts/common.ps1:149-170, scripts/common.ps1:504-560, scripts/common.ps1:685-697, scripts/doctor.ps1:55-58 |

#### Summary

Install and readiness logic searches and replaces model_provider lines without tracking TOML table scope, so a nested key can be mistaken for the global default and doctor can report success while plain Codex bypasses the proxy.

#### Root Cause

Line-oriented regexes are used to mutate and interpret a structured TOML configuration whose key meaning depends on table scope.

**All model_provider lines are treated as root** — `scripts/common.ps1:157-170`

The expression ignores active TOML table scope and replaces every matching key.

```powershell
if ($Content -match '(?m)^model_provider\s*=') {
    return [regex]::Replace(
        $Content,
        '(?m)^model_provider\s*=.*$',
        "model_provider = `"$ProviderId`""
    )
}
```

**Readiness returns first textual match** — `scripts/common.ps1:685-697`

A nested setting can be reported as the effective global provider.

```powershell
$content = Get-Content -Raw $Script:CodexConfigPath
$match = [regex]::Match($content, '(?m)^model_provider\s*=\s*"([^"]+)"')
if ($match.Success) {
    return $match.Groups[1].Value
}
```

#### Validation

With only a nested model_provider key, install rewrites that key rather than adding a root key, and doctor reads it back as if global.

Validation method: Offline parser-semantics review

- **Status:** confirmed-with-prerequisite

Assertions:
- Regex is not table aware.
- Replace has no count limit.

Counterevidence and remaining uncertainty:
- The documented simple config shape works.
- Backups are created before writes.

Limitations:
- The active user config was outside the authorized target and not read.

#### Dataflow

Preexisting TOML table key -\> section-blind rewrite -\> false doctor result -\> Codex uses non-proxy effective provider.

- **Source:** Existing config structure

- **Sink:** Direct non-proxy model provider

- **Outcome:** Prompts bypass anonymization

#### Reachability

Triggered during documented install when a section-scoped model_provider already exists.

- **Attacker:** Configuration actor or ordinary preexisting configuration

- **Entry point:** scripts/install.ps1

Preconditions:
- Config contains a nested model_provider key and no effective root privacy default.

#### Severity

**Medium** — If triggered, all later prompts may bypass anonymization; likelihood depends on a valid preexisting config containing table-scoped model_provider keys.

Additional runtime or deployment evidence could raise or lower this severity.

Impact assessment:
- **Level:** high
- **Rationale:** Subsequent prompts can be sent without the privacy layer.

Likelihood assessment:
- **Level:** medium
- **Rationale:** Depends on a plausible but unverified config shape.

#### Remediation

Use a real TOML parser to update only the root model_provider, preserve table-scoped keys, atomically replace after reparsing, and verify the effective provider through Codex or a root-aware read.

Tests:
- Install and uninstall against configs with root, nested, duplicate, profile, and commented model_provider keys.
- Verify doctor fails unless the effective global provider is the privacy provider.

Preventive controls:
- Structured TOML parsing
- Effective-configuration verification

<a id="finding-6"></a>

### [6] Unbounded analysis and retained state enable proxy resource exhaustion

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | high |
| Confidence rationale | The source directly shows missing body/session/cache limits, missing Nosey Parker subprocess timeouts, and allocation before upstream credential validation. Request models, handler flow, subprocess calls, and per-request semaphore placement directly show the missing bounds. The global dictionary, unique hash keys, unconditional insertion, full-file save, and lack of eviction are explicit. Session creation, secret insertion, and restore paths are explicit and contain no cleanup for manual sessions. Input models, subprocess calls, global dictionaries, cache persistence, and endpoint gates contain no relevant size, time, cardinality, authentication, or global concurrency bounds. |
| Category | resource-exhaustion |
| CWE | CWE-400, CWE-770 |
| Affected lines | privacy-service/app.py:19-27, privacy-service/app.py:34-73, privacy-service/app.py:153-164, privacy-service/app.py:172-203, privacy-service/proxy.py:47-68, privacy-service/proxy.py:170-221, privacy-service/proxy.py:475-524, docker-compose.yml:19-20, docker-compose.yml:50-51, privacy-service/app.py:16-27, privacy-service/app.py:34-75, privacy-service/app.py:153-218, privacy-service/proxy.py:47-68, privacy-service/proxy.py:170-221, privacy-service/proxy.py:475-543, docker-compose.yml:43-51, privacy-service/app.py:16-27, privacy-service/app.py:153-203, privacy-service/proxy.py:47-68, privacy-service/proxy.py:170-221, privacy-service/proxy.py:475-524, docker-compose.yml:48-51, privacy-service/app.py:19-27, privacy-service/app.py:34-75, privacy-service/app.py:153-218, privacy-service/proxy.py:47-68, privacy-service/proxy.py:170-221, privacy-service/proxy.py:475-512, privacy-service/app.py:19-27, privacy-service/app.py:172-178, privacy-service/proxy.py:313-332, privacy-service/proxy.py:475-521, docker-compose.yml:15-20, privacy-service/app.py:16, privacy-service/app.py:181-218, privacy-service/proxy.py:47-68, privacy-service/proxy.py:179-221, docker-compose.yml:48-49, privacy-service/app.py:19-27, privacy-service/app.py:34-75, privacy-service/app.py:172-178, privacy-service/proxy.py:170-221, privacy-service/proxy.py:313-332, privacy-service/proxy.py:475-512, docker-compose.yml:50-51, privacy-service/proxy.py:47-68, privacy-service/proxy.py:170-221, privacy-service/proxy.py:475-524, docker-compose.yml:48-51, privacy-service/app.py:16, privacy-service/app.py:172-203, privacy-service/app.py:206-218, privacy-service/app.py:16-27, privacy-service/app.py:34-73, privacy-service/app.py:153-164, privacy-service/app.py:172-218, privacy-service/proxy.py:47-68, privacy-service/proxy.py:170-221, privacy-service/proxy.py:475-522, privacy-service/app.py:16-27, privacy-service/app.py:34-75, privacy-service/app.py:153-218, privacy-service/proxy.py:47-68, privacy-service/proxy.py:170-221, docker-compose.yml:13-20, docker-compose.yml:43-51 |

#### Summary

Unauthenticated or presence-only-authenticated requests can submit unbounded bodies and structured text, allocate per-request task queues, launch detector subprocesses without deadlines or global concurrency limits, create indefinitely retained /protect sessions, and grow a host-persisted Presidio cache without eviction while repeatedly rewriting the complete cache. The proxy imposes no aggregate text, body, chunk, subprocess-time, or global concurrency limit, and any nonempty Authorization header reaches detection before upstream validation. Every unique chunk result, including empty detections, is retained in memory and the entire cache is synchronously rewritten to a host-mounted JSON file before upstream authentication succeeds. Unauthenticated /protect sessions are stored in a process-global dictionary without TTL, quotas, ownership, deletion, or cleanup after /restore. The public /protect route and header-presence-gated /responses route accept unbounded content, launch expensive detector work, and retain unbounded session or cache state. Nosey Parker subprocesses have no timeout, manual sessions never expire, and each new Presidio chunk grows a global cache that is rewritten to disk.

#### Root Cause

The loopback HTTP boundary performs expensive analysis and allocates memory, subprocess, temporary, session, and persistent-cache state without authenticated local admission or hard request, work, concurrency, time, lifecycle, entry, byte, or disk budgets. Expensive privacy work is exposed without request-size, duration, global-concurrency, or authenticated-client quotas. Attacker-influenced detector results are persisted without quota, eviction, TTL, or delayed commitment after successful authorization. The manual demonstration API treats secret mappings as process-lifetime state rather than bounded bearer sessions. Untrusted analysis endpoints lack authentication, request and nesting limits, subprocess deadlines, global concurrency quotas, and bounded eviction for retained sessions and cache data.

**Caller-named sessions never expire** — `privacy-service/app.py:153-164`

The global map has no count, size, TTL, ownership, or deletion policy for /protect sessions.

```python
if session_id not in sessions:
    sessions[session_id] = {"token_to_value": {}, "value_to_token": {}, "counters": defaultdict(int)}
return session_id, sessions[session_id]
```

**Detector subprocesses have no timeout** — `privacy-service/app.py:41-69`

Attacker-sized detector work can block indefinitely and is spawned per scan.

```python
scan = subprocess.run([...], input=enum_line, text=True, capture_output=True)
...
report = subprocess.run([...], text=True, capture_output=True)
```

**Unique chunks accumulate and persist** — `privacy-service/proxy.py:201-221`

There is no eviction or quota, and the complete cache is persisted after new chunks.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
for cache_key, spans in scanned:
    PRESIDIO_CACHE[cache_key] = spans
save_presidio_cache()
```

**Detector subprocess has no timeout** — `privacy-service/app.py:41-53`

Caller-derived content can consume unbounded subprocess time and captured output; /protect invokes this synchronously from an async route.

```python
scan = subprocess.run(
    [
        "noseyparker",
        "scan",
        "-q",
        "-d",
        datastore,
        "--enumerator=/dev/stdin",
    ],
    input=enum_line,
    text=True,
    capture_output=True,
)
```

**Protect sessions are retained globally** — `privacy-service/app.py:153-164`

There is no capacity, TTL, owner, or cleanup bound for /protect-created state; /restore reads but does not delete it.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())

    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }

    return session_id, sessions[session_id]
```

**Unique chunks accumulate and trigger a full cache rewrite** — `privacy-service/proxy.py:184-221`

Every unique chunk can create a permanent cache entry; after scanning, save_presidio_cache serializes the complete global dictionary.

```python
for core_start in range(0, len(text), chunk_size):
    core_end = min(len(text), core_start + chunk_size)
    scan_start = max(0, core_start - overlap)
    scan_end = min(len(text), core_end + overlap)
    chunk_text = text[scan_start:scan_end]
    chunk_hash = hashlib.sha256(chunk_text.encode("utf-8")).hexdigest()
    cache_key = "chunk-v1:" + chunk_hash

    hit = cache_key in PRESIDIO_CACHE

    chunks.append({
        "core_start": core_start,
        "core_end": core_end,
        "scan_start": scan_start,
        "cache_key": cache_key,
    })

    if not hit:
        missing_chunks[cache_key] = chunk_text
```

**Unbounded detector subprocess** — `privacy-service/app.py:34-75`

Caller text, child runtime, captured output, temporary storage, and process concurrency have no local bounds or timeout.

```python
scan = subprocess.run([...], input=enum_line, text=True, capture_output=True)
...
report = subprocess.run([...], text=True, capture_output=True)
```

**Every unique chunk is retained and full cache is rewritten** — `privacy-service/proxy.py:201-221`

Negative results are admitted too, with no cap, TTL, or eviction; save_presidio_cache serializes the complete dictionary to the host-mounted file.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
for cache_key, spans in scanned:
    PRESIDIO_CACHE[cache_key] = spans
save_presidio_cache()
```

**Arbitrary header value reaches expensive work** — `privacy-service/proxy.py:475-512`

A dummy Authorization value passes the local guard, and the complete analysis happens before the upstream validates it.

```python
if "authorization" not in request.headers:
    raise HTTPException(status_code=401, ...)
...
payload = await request.json()
...
payload["input"] = await protect_payload_input(payload["input"], session)
```

**Detector process has no deadline** — `privacy-service/app.py:41-53`

Caller-controlled text reaches a child process with no timeout or resource ceiling.

```python
scan = subprocess.run(
    ["noseyparker", "scan", "-q", "-d", datastore, "--enumerator=/dev/stdin"],
    input=enum_line,
    text=True,
    capture_output=True,
)
```

**Unbounded cache is fully persisted** — `privacy-service/proxy.py:61-68`

No entry, byte, age, or disk quota bounds the process-global cache.

```python
with open(PRESIDIO_CACHE_FILE, "w", encoding="utf-8") as f:
    json.dump(PRESIDIO_CACHE, f, ensure_ascii=False)
...
load_presidio_cache()
```

**Unbounded Nosey Parker subprocesses** — `privacy-service/app.py:41-53`

Each caller-controlled text scan launches a process with no application timeout or resource bound.

```python
scan = subprocess.run(
    [
        "noseyparker", "scan", "-q", "-d", datastore,
        "--enumerator=/dev/stdin",
    ],
    input=enum_line,
    text=True,
    capture_output=True,
)
```

**Scanning unlocked by header presence** — `privacy-service/proxy.py:475-512`

An arbitrary Authorization value reaches expensive privacy processing before the trusted upstream can reject it.

```python
@app.post("/responses")
async def proxy_responses(request: Request):
    if "authorization" not in request.headers:
        raise HTTPException(status_code=401, detail="Missing Codex OAuth authorization header")
...
    payload = await request.json()
...
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**No service-wide detector concurrency bound** — `privacy-service/proxy.py:206-216`

The semaphore limits chunks within one request only; concurrent requests each allocate their own queue and Nosey Parker job.

```python
semaphore = asyncio.Semaphore(1)
async def scan(cache_key, chunk_text):
    async with semaphore:
        spans = await presidio_spans(chunk_text, "lt")
        return cache_key, spans
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
```

**Sessions never expire** — `privacy-service/app.py:153-164`

Arbitrary callers can create permanent global entries with no quota or expiration.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }
    return session_id, sessions[session_id]
```

**Unique chunks retained and whole cache saved** — `privacy-service/proxy.py:213-221`

Every new chunk, including an empty detection result, becomes an unbounded memory entry and triggers persistence.

```python
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

**Cache survives container restarts** — `docker-compose.yml:48-49`

Attacker-driven cache growth is written to a host-mounted directory and persists across container recreation.

```yaml
volumes:
  - ./privacy-cache:/app/cache
```

**Nosey Parker subprocess has no timeout** — `privacy-service/app.py:41-53`

Caller-controlled text can drive an indefinitely long blocking native process.

```python
scan = subprocess.run(
    [
        "noseyparker",
        "scan",
        "-q",
        "-d",
        datastore,
        "--enumerator=/dev/stdin",
    ],
    input=enum_line,
    text=True,
    capture_output=True,
)
```

**Detector work requires only header presence** — `privacy-service/proxy.py:475-484`

Upstream validity is not established before local detector resources are consumed.

```python
@app.post("/responses")
async def proxy_responses(request: Request):
    if "authorization" not in request.headers:
        raise HTTPException(
            status_code=401,
            detail=(
                "Missing Codex OAuth "
                "authorization header"
            ),
        )
```

**Every new chunk is retained and the full cache is saved** — `privacy-service/proxy.py:213-221`

There is no entry, byte, age, tenant, or write-amplification bound.

```python
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )

    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans

    save_presidio_cache()
```

**The whole cache is synchronously rewritten** — `privacy-service/proxy.py:61-66`

Increasing cardinality causes increasing synchronous memory and disk work.

```python
def save_presidio_cache():
    try:
        with open(PRESIDIO_CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(PRESIDIO_CACHE, f, ensure_ascii=False)
    except Exception as exc:
        print(json.dumps({"cache_save_error": type(exc).__name__}), flush=True)
```

**Sessions are created without expiration or quota** — `privacy-service/app.py:153-164`

Caller-selected or generated sessions persist indefinitely in the global dictionary.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())

    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }

    return session_id, sessions[session_id]
```

**Restore leaves the secret session intact** — `privacy-service/app.py:206-218`

Successful restoration does not delete, age, or reduce the stored mappings.

```python
@app.post("/restore")
def restore(req: RestoreRequest):
    session = sessions.get(req.session_id)

    if not session:
        raise HTTPException(status_code=404, detail="Unknown session")

    output = req.text

    for token, original in session["token_to_value"].items():
        output = output.replace(token, original)

    return {"text": output}
```

**Nosey Parker subprocesses have no execution timeout** — `privacy-service/app.py:34-73`

Attacker-sized input reaches external processes with neither a subprocess timeout nor a global scanner quota.

```python
scan = subprocess.run(
    ["noseyparker", "scan", "-q", "-d", datastore, "--enumerator=/dev/stdin"],
    input=enum_line,
    text=True,
    capture_output=True,
)
...
report = subprocess.run(
    ["noseyparker", "report", "-q", "-d", datastore, "--format", "json"],
    text=True,
    capture_output=True,
)
```

**Caller-selected sessions are retained indefinitely** — `privacy-service/app.py:153-164`

Manual /protect sessions have no TTL, byte budget, maximum count, or deletion path.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }
    return session_id, sessions[session_id]
```

**Every unique chunk grows and rewrites the persistent cache** — `privacy-service/proxy.py:201-221`

A fake Authorization value passes the local gate and can create arbitrarily many tasks, memory entries, and full-cache disk rewrites before upstream authentication.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

**Blocking scanner has no deadline** — `privacy-service/app.py:34-53`

Caller text drives an external process with no wall-clock or output limit.

```python
scan = subprocess.run(
 ["noseyparker", "scan", "-q", "-d", datastore, "--enumerator=/dev/stdin"],
 input=enum_line, text=True, capture_output=True,
)
```

**Manual sessions retain originals indefinitely** — `privacy-service/app.py:153-164`

No TTL, size budget, or eviction exists for /protect sessions.

```python
if session_id not in sessions:
    sessions[session_id] = {
      "token_to_value": {}, "value_to_token": {}, "counters": defaultdict(int),
    }
return session_id, sessions[session_id]
```

**Unique chunks are retained** — `privacy-service/proxy.py:213-221`

Global cache entries are persisted without count, byte, or age limits.

```python
if missing_chunks:
    scanned = await asyncio.gather(...)
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

#### Validation

Static validation confirmed independently reachable oversized-work, stalled-subprocess, retained-session, and persistent-cache-growth paths. The shipped loopback bind constrains the default attacker to another local process; widened binding increases exposure. An oversized /protect request or /responses request with an arbitrary Authorization value reaches memory allocation and detector execution without an application bound. Each fresh 4000-character chunk yields a new SHA-256 key and permanent cache entry even when no PII is found; the full map is saved before the upstream can reject a fake token. Repeated unauthenticated /protect requests with unique session IDs and detected values monotonically grow the global store; /restore never cleans it. An unauthenticated local caller can use /protect directly; /responses accepts any Authorization header value before detector work. Both paths allocate work or retained state without enforceable budgets.

Validation method: Source review of request models, endpoint order, detector execution, state cleanup, and Compose exposure. Independent baseline and backward sensitive-operation review followed by parent source revalidation.

- **Status:** validated-with-default-local-scope
- **Disposition:** report

**Caller-named sessions never expire** — `privacy-service/app.py:153-164`

The global map has no count, size, TTL, ownership, or deletion policy for /protect sessions.

```python
if session_id not in sessions:
    sessions[session_id] = {"token_to_value": {}, "value_to_token": {}, "counters": defaultdict(int)}
return session_id, sessions[session_id]
```

**Detector subprocesses have no timeout** — `privacy-service/app.py:41-69`

Attacker-sized detector work can block indefinitely and is spawned per scan.

```python
scan = subprocess.run([...], input=enum_line, text=True, capture_output=True)
...
report = subprocess.run([...], text=True, capture_output=True)
```

**Unique chunks accumulate and persist** — `privacy-service/proxy.py:201-221`

There is no eviction or quota, and the complete cache is persisted after new chunks.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
for cache_key, spans in scanned:
    PRESIDIO_CACHE[cache_key] = spans
save_presidio_cache()
```

**Detector subprocess has no timeout** — `privacy-service/app.py:41-53`

Caller-derived content can consume unbounded subprocess time and captured output; /protect invokes this synchronously from an async route.

```python
scan = subprocess.run(
    [
        "noseyparker",
        "scan",
        "-q",
        "-d",
        datastore,
        "--enumerator=/dev/stdin",
    ],
    input=enum_line,
    text=True,
    capture_output=True,
)
```

**Protect sessions are retained globally** — `privacy-service/app.py:153-164`

There is no capacity, TTL, owner, or cleanup bound for /protect-created state; /restore reads but does not delete it.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())

    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }

    return session_id, sessions[session_id]
```

**Unique chunks accumulate and trigger a full cache rewrite** — `privacy-service/proxy.py:184-221`

Every unique chunk can create a permanent cache entry; after scanning, save_presidio_cache serializes the complete global dictionary.

```python
for core_start in range(0, len(text), chunk_size):
    core_end = min(len(text), core_start + chunk_size)
    scan_start = max(0, core_start - overlap)
    scan_end = min(len(text), core_end + overlap)
    chunk_text = text[scan_start:scan_end]
    chunk_hash = hashlib.sha256(chunk_text.encode("utf-8")).hexdigest()
    cache_key = "chunk-v1:" + chunk_hash

    hit = cache_key in PRESIDIO_CACHE

    chunks.append({
        "core_start": core_start,
        "core_end": core_end,
        "scan_start": scan_start,
        "cache_key": cache_key,
    })

    if not hit:
        missing_chunks[cache_key] = chunk_text
```

**Unbounded detector subprocess** — `privacy-service/app.py:34-75`

Caller text, child runtime, captured output, temporary storage, and process concurrency have no local bounds or timeout.

```python
scan = subprocess.run([...], input=enum_line, text=True, capture_output=True)
...
report = subprocess.run([...], text=True, capture_output=True)
```

**Every unique chunk is retained and full cache is rewritten** — `privacy-service/proxy.py:201-221`

Negative results are admitted too, with no cap, TTL, or eviction; save_presidio_cache serializes the complete dictionary to the host-mounted file.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
for cache_key, spans in scanned:
    PRESIDIO_CACHE[cache_key] = spans
save_presidio_cache()
```

**Arbitrary header value reaches expensive work** — `privacy-service/proxy.py:475-512`

A dummy Authorization value passes the local guard, and the complete analysis happens before the upstream validates it.

```python
if "authorization" not in request.headers:
    raise HTTPException(status_code=401, ...)
...
payload = await request.json()
...
payload["input"] = await protect_payload_input(payload["input"], session)
```

**Unbounded Nosey Parker subprocesses** — `privacy-service/app.py:41-53`

Each caller-controlled text scan launches a process with no application timeout or resource bound.

```python
scan = subprocess.run(
    [
        "noseyparker", "scan", "-q", "-d", datastore,
        "--enumerator=/dev/stdin",
    ],
    input=enum_line,
    text=True,
    capture_output=True,
)
```

**Scanning unlocked by header presence** — `privacy-service/proxy.py:475-512`

An arbitrary Authorization value reaches expensive privacy processing before the trusted upstream can reject it.

```python
@app.post("/responses")
async def proxy_responses(request: Request):
    if "authorization" not in request.headers:
        raise HTTPException(status_code=401, detail="Missing Codex OAuth authorization header")
...
    payload = await request.json()
...
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**No service-wide detector concurrency bound** — `privacy-service/proxy.py:206-216`

The semaphore limits chunks within one request only; concurrent requests each allocate their own queue and Nosey Parker job.

```python
semaphore = asyncio.Semaphore(1)
async def scan(cache_key, chunk_text):
    async with semaphore:
        spans = await presidio_spans(chunk_text, "lt")
        return cache_key, spans
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
```

**Sessions never expire** — `privacy-service/app.py:153-164`

Arbitrary callers can create permanent global entries with no quota or expiration.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }
    return session_id, sessions[session_id]
```

**Unique chunks retained and whole cache saved** — `privacy-service/proxy.py:213-221`

Every new chunk, including an empty detection result, becomes an unbounded memory entry and triggers persistence.

```python
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

**Cache survives container restarts** — `docker-compose.yml:48-49`

Attacker-driven cache growth is written to a host-mounted directory and persists across container recreation.

```yaml
volumes:
  - ./privacy-cache:/app/cache
```

**Nosey Parker subprocesses have no execution timeout** — `privacy-service/app.py:34-73`

Attacker-sized input reaches external processes with neither a subprocess timeout nor a global scanner quota.

```python
scan = subprocess.run(
    ["noseyparker", "scan", "-q", "-d", datastore, "--enumerator=/dev/stdin"],
    input=enum_line,
    text=True,
    capture_output=True,
)
...
report = subprocess.run(
    ["noseyparker", "report", "-q", "-d", datastore, "--format", "json"],
    text=True,
    capture_output=True,
)
```

**Caller-selected sessions are retained indefinitely** — `privacy-service/app.py:153-164`

Manual /protect sessions have no TTL, byte budget, maximum count, or deletion path.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }
    return session_id, sessions[session_id]
```

**Every unique chunk grows and rewrites the persistent cache** — `privacy-service/proxy.py:201-221`

A fake Authorization value passes the local gate and can create arbitrarily many tasks, memory entries, and full-cache disk rewrites before upstream authentication.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

**Blocking scanner has no deadline** — `privacy-service/app.py:34-53`

Caller text drives an external process with no wall-clock or output limit.

```python
scan = subprocess.run(
 ["noseyparker", "scan", "-q", "-d", datastore, "--enumerator=/dev/stdin"],
 input=enum_line, text=True, capture_output=True,
)
```

**Manual sessions retain originals indefinitely** — `privacy-service/app.py:153-164`

No TTL, size budget, or eviction exists for /protect sessions.

```python
if session_id not in sessions:
    sessions[session_id] = {
      "token_to_value": {}, "value_to_token": {}, "counters": defaultdict(int),
    }
return session_id, sessions[session_id]
```

**Unique chunks are retained** — `privacy-service/proxy.py:213-221`

Global cache entries are persisted without count, byte, or age limits.

```python
if missing_chunks:
    scanned = await asyncio.gather(...)
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

Assertions:
- /protect accepts unbounded text without authentication.
- /responses checks only header presence before scanning.
- /protect sessions and cache entries are not evicted.
- Nosey Parker subprocesses have no timeout.
- ProtectRequest strings have no max_length and /responses buffers request.json() without a body limit.
- Both Nosey Parker subprocess calls omit timeout.
- /protect sessions have no delete or expiry path.
- The cache has no eviction and is persisted to a bind-mounted host directory.
- /responses checks only Authorization header presence before scanning, so an arbitrary value reaches expensive local work.
- Pydantic text fields and raw request JSON are unconstrained.
- The Presidio semaphore is per request and asyncio.gather is constructed for all misses.
- Standalone /protect sessions are never removed; cache entries, including empty results, are never evicted.
- ProtectRequest.text has no maximum.
- Standalone sessions never expire.
- Fake Authorization values pass the local /responses gate.
- /protect has no authentication and no text-length limit.
- /responses checks only Authorization header presence before scanning.
- Nosey Parker subprocesses lack a timeout.
- Detector concurrency is not bounded across requests.
- Every unknown session identifier creates a global entry.
- Detected originals are retained in both mapping directions.
- Manual restore does not delete or expire the session.
- Every unique chunk hash and spans array is cached without a limit and persisted.
- No request model constrains text length.
- subprocess.run has no timeout.
- The Presidio semaphore is created per request and is not a global limit.
- Detection precedes upstream authorization rejection.
- Cache keys are hashes of exact chunk text.
- Empty result arrays are cached.
- No eviction or capacity check exists.
- The cache directory is host-mounted.
- No TTL, LRU, session-count limit, or per-session value limit exists.
- Both token-to-original and original-to-token dictionaries retain plaintext.
- Manual sessions are not covered by /responses cleanup paths.
- Request text and session identifiers have no maximum length.
- Manual sessions never expire.
- The cache has no capacity or age bound and is persisted in full.
- The Presidio semaphore is per request and does not bound concurrent requests.

Counterevidence and remaining uncertainty:
- Both ports default to 127.0.0.1.
- Presidio HTTP calls have a 120-second timeout.
- A per-request semaphore serializes Presidio calls within one request.
- /responses sessions are removed on errors and stream completion.
- Presidio HTTP requests have a 120-second timeout.
- /responses moves Nosey Parker work to a thread and normally removes its temporary session.
- The shipped proxy bind is 127.0.0.1.
- Session state is memory-only and disappears on process restart.
- Default Compose binding is 127.0.0.1.
- Presidio calls have a 120-second timeout and /responses sessions are removed on visible completion/error paths.
- Nosey Parker is invoked with a safe argument array, so this is not command injection.
- Default publication is loopback.
- Presidio HTTP has a 120-second timeout.
- Responses sessions are normally cleaned up.
- TemporaryDirectory removes finished datastores.
- Individual chunks are approximately bounded, although aggregate chunk count is not.
- /responses sessions are removed on failure, upstream errors, and stream finalization.
- The cache stores a hash and span metadata rather than raw chunks.
- Identical chunks are deduplicated.
- Process restart clears in-memory sessions but not the persistent cache.
- Compose defaults to loopback.
- Presidio HTTP calls have a 120-second timeout and the analyzer has a 300-second Gunicorn timeout.
- Original chunk text is not persisted.
- Default loopback binding restricts remote access.
- Generated IDs use UUIDv4 and are not practically guessable.
- Internally created /responses sessions are removed on failure, upstream error, or stream completion.
- The default bind address is 127.0.0.1.
- Temporary Nosey Parker directories are cleaned after process completion.
- Temporary /responses sessions are removed on failure or stream completion.
- Default bind is 127.0.0.1.
- Presidio HTTP has a timeout.
- Ephemeral /responses sessions are cleaned.
- Restart clears memory but not persisted cache.

Limitations:
- No load test was run.
- No runtime load test or exhaustion-threshold measurement was performed.
- No load test or runtime resource measurement was performed.
- No disk-fill benchmark was performed.
- No runtime memory-growth measurement was performed.

#### Dataflow

Untrusted HTTP bodies -\> detector subprocess/tasks and global maps -\> CPU, RAM, temporary disk, and persistent disk exhaustion. Oversized/unique request -\> JSON and corpus allocation -\> Presidio tasks plus Nosey Parker subprocesses -\> CPU/memory/process exhaustion. Unique request chunks -\> detector results -\> global dictionary -\> full JSON rewrite to host volume -\> memory/disk exhaustion. Unique /protect request -\> session creation -\> plaintext mappings in global dictionary -\> no expiration or deletion. HTTP body -\> JSON/Pydantic parsing -\> detector subprocesses and analyzer chunks -\> global sessions/cache -\> memory and persistent volume.

Attack steps:
- Reach /protect without authentication or /responses with any Authorization value.
- Submit large text, many unique chunks, or many chosen session IDs.
- Trigger Nosey Parker processes and Presidio work.
- Accumulate unbounded in-memory sessions/cache and persistent cache rewrites.

- **Source:** POST /protect and POST /responses Untrusted request body Caller-controlled unique input Caller-controlled session IDs and detected values Unauthenticated /protect input or /responses input with any Authorization header

- **Sink:** Nosey Parker, Presidio task set, sessions, PRESIDIO_CACHE_FILE Detector processes, event loop, thread pool, and memory PRESIDIO_CACHE and /app/cache/presidio-cache.json Process-global sessions dictionary Nosey Parker processes, analyzer tasks, process memory, and /app/cache/presidio-cache.json

- **Outcome:** Privacy proxy availability degradation or termination. Proxy denial of service Persistent denial of service and write amplification Memory exhaustion and extended plaintext retention Service unavailability, memory pressure, CPU exhaustion, or disk growth

Transformations:
- JSON parsing
- slot/corpus duplication
- chunking
- persistent cache serialization
- Parse unbounded request body.
- Collect and duplicate text into slots, corpora, chunks, and task lists.
- Run Nosey Parker and Presidio before upstream credential validation.
- Create a session for every unknown identifier.
- Store detected originals in two mappings.
- Hash each unique text chunk and retain its spans.
- Rewrite the full cache into a host bind mount.
- Body parsing
- slot collection
- corpus construction
- chunk fan-out
- session mapping
- full-cache JSON serialization

**Caller-named sessions never expire** — `privacy-service/app.py:153-164`

The global map has no count, size, TTL, ownership, or deletion policy for /protect sessions.

```python
if session_id not in sessions:
    sessions[session_id] = {"token_to_value": {}, "value_to_token": {}, "counters": defaultdict(int)}
return session_id, sessions[session_id]
```

**Detector subprocesses have no timeout** — `privacy-service/app.py:41-69`

Attacker-sized detector work can block indefinitely and is spawned per scan.

```python
scan = subprocess.run([...], input=enum_line, text=True, capture_output=True)
...
report = subprocess.run([...], text=True, capture_output=True)
```

**Unique chunks accumulate and persist** — `privacy-service/proxy.py:201-221`

There is no eviction or quota, and the complete cache is persisted after new chunks.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
for cache_key, spans in scanned:
    PRESIDIO_CACHE[cache_key] = spans
save_presidio_cache()
```

**Unbounded Nosey Parker subprocesses** — `privacy-service/app.py:41-53`

Each caller-controlled text scan launches a process with no application timeout or resource bound.

```python
scan = subprocess.run(
    [
        "noseyparker", "scan", "-q", "-d", datastore,
        "--enumerator=/dev/stdin",
    ],
    input=enum_line,
    text=True,
    capture_output=True,
)
```

**Scanning unlocked by header presence** — `privacy-service/proxy.py:475-512`

An arbitrary Authorization value reaches expensive privacy processing before the trusted upstream can reject it.

```python
@app.post("/responses")
async def proxy_responses(request: Request):
    if "authorization" not in request.headers:
        raise HTTPException(status_code=401, detail="Missing Codex OAuth authorization header")
...
    payload = await request.json()
...
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**No service-wide detector concurrency bound** — `privacy-service/proxy.py:206-216`

The semaphore limits chunks within one request only; concurrent requests each allocate their own queue and Nosey Parker job.

```python
semaphore = asyncio.Semaphore(1)
async def scan(cache_key, chunk_text):
    async with semaphore:
        spans = await presidio_spans(chunk_text, "lt")
        return cache_key, spans
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
```

**Sessions never expire** — `privacy-service/app.py:153-164`

Arbitrary callers can create permanent global entries with no quota or expiration.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }
    return session_id, sessions[session_id]
```

**Unique chunks retained and whole cache saved** — `privacy-service/proxy.py:213-221`

Every new chunk, including an empty detection result, becomes an unbounded memory entry and triggers persistence.

```python
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

**Cache survives container restarts** — `docker-compose.yml:48-49`

Attacker-driven cache growth is written to a host-mounted directory and persists across container recreation.

```yaml
volumes:
  - ./privacy-cache:/app/cache
```

**Nosey Parker subprocesses have no execution timeout** — `privacy-service/app.py:34-73`

Attacker-sized input reaches external processes with neither a subprocess timeout nor a global scanner quota.

```python
scan = subprocess.run(
    ["noseyparker", "scan", "-q", "-d", datastore, "--enumerator=/dev/stdin"],
    input=enum_line,
    text=True,
    capture_output=True,
)
...
report = subprocess.run(
    ["noseyparker", "report", "-q", "-d", datastore, "--format", "json"],
    text=True,
    capture_output=True,
)
```

**Caller-selected sessions are retained indefinitely** — `privacy-service/app.py:153-164`

Manual /protect sessions have no TTL, byte budget, maximum count, or deletion path.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }
    return session_id, sessions[session_id]
```

**Every unique chunk grows and rewrites the persistent cache** — `privacy-service/proxy.py:201-221`

A fake Authorization value passes the local gate and can create arbitrarily many tasks, memory entries, and full-cache disk rewrites before upstream authentication.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

#### Reachability

Direct from any local process under the default loopback binding; remote if PROXY_BIND_HOST is widened. Unauthenticated /protect is directly reachable; /responses requires only any Authorization header before expensive work. Reachable before upstream credential validation with any nonempty Authorization header. Directly reachable through the unauthenticated /protect endpoint on the loopback service. Any local process can reach the default published port; remote callers become eligible if the operator widens PROXY_BIND_HOST.

- **Attacker:** Local unprivileged process by default, otherwise reachable network caller Untrusted local process by default or network peer after non-loopback binding Untrusted local process or network peer in an exposed deployment Untrusted local process, or network peer after non-loopback exposure Local unauthenticated process by default

- **Entry point:** /protect or /responses POST /protect or POST /responses

- **Source:** Oversized, deeply nested, numerous, or unique request content

- **Sink:** Unbounded detector and retention resources Detector execution Host-mounted privacy cache Global sessions state Unbounded detector and state resources

- **Outcome:** Denial of service. Availability loss Disk, memory, or latency exhaustion Availability loss; later recovery if a session ID is disclosed Privacy proxy denial of service

Preconditions:
- The attacker can connect to the proxy port.
- Network reachability to the published proxy port.
- The attacker can connect to the published proxy port.
- For /responses, the attacker supplies any Authorization header.
- The caller can connect to the proxy.
- For cache growth, the caller supplies unique text and any Authorization header.
- Loopback access, or non-loopback exposure for remote exploitation.
- Sustained access to the proxy.
- Access to the proxy port.
- Loopback access, or network reachability after non-default binding

Existing controls:
- Default loopback binding
- Presidio HTTP timeout
- Per-request Presidio semaphore
- Loopback default binding
- Temporary datastore cleanup on normal subprocess completion
- Per-request /responses session cleanup
- SHA-256 cache deduplication
- Raw chunks are not persisted
- Loopback binding by default
- Single-request Presidio semaphore
- 120-second analyzer HTTP timeout
- Temporary-directory cleanup

Limitations:
- Controls reduce attacker population or one sub-operation but do not impose an end-to-end budget.

**Unbounded Nosey Parker subprocesses** — `privacy-service/app.py:41-53`

Each caller-controlled text scan launches a process with no application timeout or resource bound.

```python
scan = subprocess.run(
    [
        "noseyparker", "scan", "-q", "-d", datastore,
        "--enumerator=/dev/stdin",
    ],
    input=enum_line,
    text=True,
    capture_output=True,
)
```

**Scanning unlocked by header presence** — `privacy-service/proxy.py:475-512`

An arbitrary Authorization value reaches expensive privacy processing before the trusted upstream can reject it.

```python
@app.post("/responses")
async def proxy_responses(request: Request):
    if "authorization" not in request.headers:
        raise HTTPException(status_code=401, detail="Missing Codex OAuth authorization header")
...
    payload = await request.json()
...
    payload["input"] = await protect_payload_input(
        payload["input"],
        session,
    )
```

**No service-wide detector concurrency bound** — `privacy-service/proxy.py:206-216`

The semaphore limits chunks within one request only; concurrent requests each allocate their own queue and Nosey Parker job.

```python
semaphore = asyncio.Semaphore(1)
async def scan(cache_key, chunk_text):
    async with semaphore:
        spans = await presidio_spans(chunk_text, "lt")
        return cache_key, spans
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
```

**Sessions never expire** — `privacy-service/app.py:153-164`

Arbitrary callers can create permanent global entries with no quota or expiration.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }
    return session_id, sessions[session_id]
```

**Unique chunks retained and whole cache saved** — `privacy-service/proxy.py:213-221`

Every new chunk, including an empty detection result, becomes an unbounded memory entry and triggers persistence.

```python
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

**Cache survives container restarts** — `docker-compose.yml:48-49`

Attacker-driven cache growth is written to a host-mounted directory and persists across container recreation.

```yaml
volumes:
  - ./privacy-cache:/app/cache
```

**Nosey Parker subprocesses have no execution timeout** — `privacy-service/app.py:34-73`

Attacker-sized input reaches external processes with neither a subprocess timeout nor a global scanner quota.

```python
scan = subprocess.run(
    ["noseyparker", "scan", "-q", "-d", datastore, "--enumerator=/dev/stdin"],
    input=enum_line,
    text=True,
    capture_output=True,
)
...
report = subprocess.run(
    ["noseyparker", "report", "-q", "-d", datastore, "--format", "json"],
    text=True,
    capture_output=True,
)
```

**Every unique chunk grows and rewrites the persistent cache** — `privacy-service/proxy.py:201-221`

A fake Authorization value passes the local gate and can create arbitrarily many tasks, memory entries, and full-cache disk rewrites before upstream authentication.

```python
if not hit:
    missing_chunks[cache_key] = chunk_text
...
if missing_chunks:
    scanned = await asyncio.gather(
        *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
    )
    for cache_key, spans in scanned:
        PRESIDIO_CACHE[cache_key] = spans
    save_presidio_cache()
```

#### Severity

**Low** — The path is reliable but defaults to a same-host loopback attacker and primarily affects availability. Widening the bind address without authentication materially increases severity. The default loopback bind limits the attacker to local processes, but an exposed deployment permits unauthenticated remote CPU, memory, process, and thread exhaustion. Sustained requests can fill memory or disk and amplify writes, but default loopback confinement and the traffic volume required reduce likelihood. The flaw permits local memory exhaustion and extends plaintext-secret lifetime, but UUIDv4 session IDs and loopback binding reduce cross-client disclosure likelihood. The code supports reliable availability degradation and storage growth, but the default listener is loopback and the impact is confined to the local privacy service. Network exposure or shared-host use increases severity.

Treat as medium when either service is reachable by untrusted remote clients or when availability of the privacy proxy is operationally critical. Severity increases to medium or high when PROXY_BIND_HOST exposes the proxy to untrusted network peers. Severity increases for network-exposed or multi-user deployments without filesystem quotas. Severity increases for shared or network-exposed deployments or if session identifiers are logged or otherwise disclosed. Raise to medium when PROXY_BIND_HOST is non-loopback, untrusted tenants share the host, or the proxy protects an availability-critical workflow.

Impact assessment:
- **Level:** medium
- **Rationale:** The local privacy service can be made unavailable and sensitive originals retained unnecessarily. Legitimate Codex traffic can be delayed or denied and host resources can be consumed. The proxy can become slow or unavailable and the host volume can fill. The process can be exhausted and plaintext values remain recoverable longer than necessary. The local privacy workflow can become unavailable and disk/memory can be consumed.

Likelihood assessment:
- **Level:** high low
- **Rationale:** Allocation and work are directly attacker-controlled with no quotas. Default exposure is localhost, reducing the attacker population. Requires sustained unique traffic and default exposure is loopback. Default attacker population is limited to local processes. No valid credential is required for /protect, and any header value reaches /responses detector work.

#### Remediation

Require a high-entropy per-install local admission credential before body parsing or analysis. Enforce Content-Length and streamed ASGI limits, JSON depth/node limits, per-string and aggregate text limits, slot/chunk/task caps, global rate/concurrency limits, and bounded work queues. Move blocking detector work to bounded workers; impose Nosey Parker process/output/temp quotas and hard deadlines plus absolute stream deadlines. Use short-lived bounded TTL/LRU session state with explicit or one-shot deletion, versioned byte/entry-limited cache storage with eviction and atomic incremental persistence, and container CPU, memory, PID, and disk quotas. Enforce Content-Length, decoded-body, per-field, aggregate-text, chunk-count, and concurrency limits; add hard subprocess timeouts with process-group termination; use a global bounded work queue and return 413 or 429 before detector allocation. Use a bounded TTL/LRU cache with maximum entries and bytes, avoid full-object rewrites, apply filesystem quotas, and do not persist results for requests that fail local or upstream authorization. Add short TTLs, per-session and global quotas, LRU eviction, and explicit delete or delete-after-restore behavior. Treat session IDs as bearer secrets, bind them to authenticated clients in shared deployments, and reject arbitrary caller-selected IDs unless ownership is established. Authenticate local clients independently of the upstream token. Enforce server-level body, field-length, nesting, slot, and chunk limits before expensive parsing and scanning. Apply global request and scanner concurrency quotas, hard subprocess timeouts with child termination, and per-client rate limits. Add session TTLs, explicit deletion, maximum counts and retained-byte budgets. Bound the Presidio cache with LRU/TTL and disk quotas, and persist updates atomically without rewriting an unbounded dataset.

Tests:
- Verify oversized bodies, excessive JSON depth, slot counts, and chunk counts are rejected before detector invocation.
- Verify stalled Nosey Parker processes are terminated at a fixed deadline.
- Create sessions/cache entries past configured quotas and assert eviction or rejection with bounded memory/disk use.
- Verify a dummy Authorization header cannot commit persistent cache state before client authentication.
- Assert oversized bodies and strings fail with 413 before detector invocation.
- Assert detector subprocesses are terminated at a hard deadline.
- Flood unique protect and responses requests and verify session/cache byte and entry counts stay within configured bounds.
- Restart or cancel streams and verify all temporary plaintext mappings are removed.
- Verify oversized bodies, excessive nesting, too many strings/chunks, and long detector runs fail before expensive work.
- Verify a dummy Authorization value cannot trigger analysis without a valid local admission credential.
- Exercise cache/session caps and assert bounded memory, file size, rewrite latency, and TTL eviction.
- Verify oversized bodies return 413 before detector execution.
- Verify fake Authorization cannot mutate cache.
- Verify session/cache quotas and subprocess deadlines under repeated requests.
- Oversized bodies, excessive JSON depth, slot counts, aggregate text, and chunk counts are rejected before detector invocation.
- Concurrent requests never exceed configured global Presidio and Nosey Parker limits.
- A hung Nosey Parker child and its descendants are terminated at the deadline.
- A junk Authorization value cannot consume unbounded work.
- Loopback is the only default published address.
- Creating more than the configured session count evicts or rejects entries deterministically.
- Manual restore consumes or expires sessions according to policy.
- Per-session mappings and retained bytes cannot exceed configured limits.
- Unique cache inputs never grow memory or disk beyond the configured cap.
- Container restart and cache reload preserve the cap and do not resurrect expired data.
- Assert oversized bodies and aggregate text are rejected with 413 before analyzer or subprocess invocation.
- Assert timed-out Nosey Parker processes are terminated and concurrent work is capped globally.
- Verify fake Authorization values cannot populate expensive work indefinitely in shared deployments.
- Insert more than the configured cache limit and assert deterministic eviction plus bounded file size.
- Send requests rejected by authorization and assert they do not increase persistent cache cardinality.
- Measure rewrite cost remains bounded as unique inputs accumulate.
- Create sessions beyond configured limits and assert eviction plus bounded memory.
- Advance time beyond TTL and assert restore fails and plaintext mappings are gone.
- Assert delete-after-restore removes the session when requested.
- Verify oversized bodies, excessive nesting, too many slots, and overlong session IDs are rejected before any subprocess or analyzer call.
- Send concurrent fake-Authorization /responses requests and assert global scanner, task, memory, and cache quotas hold.
- Use a deliberately hanging scanner fixture and require timeout plus child-process termination.
- Advance time or exceed quotas and verify sessions/cache entries are evicted and disk use remains bounded.
- Reject oversized bodies and excessive nesting before detector calls.
- Terminate stalled scanners while health remains responsive.
- Keep session and cache counts/bytes under fixed budgets.

Preventive controls:
- ASGI request limits
- Global detector quotas
- Bounded TTL session/cache stores
- Loopback-only enforcement unless authenticated
- Admission limits before request parsing
- Authenticated local API and rate limiting
- Bounded detector worker pool with timeouts
- TTL and quota enforcement for sessions and cache
- Container resource quotas
- Local admission authentication
- Body and structure quotas
- Global concurrency/rate limits
- Subprocess deadlines
- Bounded cache and session lifecycle
- Local authentication
- Admission and rate limits
- Bounded TTL/LRU state
- Local caller authentication
- Pre-parse and semantic request limits
- Service-wide concurrency limits
- Subprocess and container resource limits
- Rate limiting and backpressure
- TTL/LRU state stores
- Per-caller and global byte quotas
- One-time or explicitly managed sessions
- Bounded persistent cache and volume quota
- Minimal plaintext retention
- ASGI body-size middleware
- Global detector semaphore and bounded queue
- Subprocess timeout and termination
- Per-client quotas
- TTL/LRU cache
- Byte and entry quotas
- Transactional bounded storage
- Filesystem quota
- Session TTL and LRU
- Global and per-session quotas
- Authenticated ownership
- Explicit destruction
- Authenticated loopback client capability
- End-to-end resource budgets
- Bounded worker pools and subprocess deadlines
- TTL/LRU session and cache eviction
- Admission limits
- Scanner timeouts
- Rate/concurrency limits
- TTL/LRU state
- Container quotas

<a id="finding-7"></a>

### [7] Caller-addressable sessions permit cross-client plaintext restoration

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | medium |
| Confidence rationale | The missing ownership check is explicit, but a realistic path for learning an automatically generated victim session ID is not established by repository source. |
| Category | session-ownership-bypass |
| CWE | CWE-639 |
| Affected lines | privacy-service/app.py:153-164, privacy-service/app.py:172-203, privacy-service/app.py:206-218, privacy-service/app.py:19-27, privacy-service/app.py:153-164, privacy-service/app.py:172-203, privacy-service/app.py:206-218, docker-compose.yml:50-51 |

#### Summary

The standalone /protect and /restore APIs accept or reuse a caller-selected session_id as the sole selector and bearer authorization for a process-global plaintext map. A caller who fixes or learns an identifier can append mappings and expand predictable GP_\* tokens without owner binding, expiry, or one-time-use control.

#### Root Cause

A caller-controlled reusable identifier serves simultaneously as global object key and sole bearer authorization for sensitive mappings, with no authenticated principal binding or lifecycle enforcement.

**Caller-selected global session** — `privacy-service/app.py:153-164`

An existing mapping is returned solely by its external identifier.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {...}
    return session_id, sessions[session_id]
```

**No ownership check before substitution** — `privacy-service/app.py:206-216`

Possession of the session ID is sufficient to expand predictable placeholders.

```python
session = sessions.get(req.session_id)
if not session:
    raise HTTPException(status_code=404, detail="Unknown session")
output = req.text
for token, original in session["token_to_value"].items():
    output = output.replace(token, original)
```

**Caller ID directly indexes global map** — `privacy-service/app.py:153-164`

Supplied IDs are accepted without entropy validation, ownership, authentication, rotation, or expiry.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {...}
    return session_id, sessions[session_id]
```

**Session ID alone authorizes restoration** — `privacy-service/app.py:206-218`

A caller knowing a shared ID can enumerate predictable entity counters and recover mapped plaintext.

```python
session = sessions.get(req.session_id)
...
for token, original in session["token_to_value"].items():
    output = output.replace(token, original)
return {"text": output}
```

#### Validation

The missing ownership check, caller-selected key, predictable token allocation, and restoration oracle are explicit. Cross-client disclosure requires a standalone integration to reuse, disclose, or accept an attacker-known ID; default UUIDv4 IDs are not practically guessable, bundled examples use returned random IDs, /responses sessions are internal and deleted, and the service is loopback-only by default.

Validation method: Offline route and state review

- **Status:** confirmed-with-prerequisite

**Caller ID directly indexes global map** — `privacy-service/app.py:153-164`

Supplied IDs are accepted without entropy validation, ownership, authentication, rotation, or expiry.

```python
def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())
    if session_id not in sessions:
        sessions[session_id] = {...}
    return session_id, sessions[session_id]
```

**Session ID alone authorizes restoration** — `privacy-service/app.py:206-218`

A caller knowing a shared ID can enumerate predictable entity counters and recover mapped plaintext.

```python
session = sessions.get(req.session_id)
...
for token, original in session["token_to_value"].items():
    output = output.replace(token, original)
return {"text": output}
```

Assertions:
- No local authentication exists.
- Session IDs can be caller-selected.
- Both routes are exposed on the same FastAPI application.
- No session owner, authentication middleware, TTL, or one-time-use control exists.

Counterevidence and remaining uncertainty:
- Server-generated IDs are UUID4.
- Responses sessions are internal and deleted.
- Omitted IDs are generated with UUIDv4.
- The default bind address is loopback.
- Bundled examples normally reuse the returned random ID.
- The worker did not establish blind enumeration of server-generated UUIDv4 session identifiers or cross-client theft of internal request-scoped /responses sessions.

Limitations:
- No source-backed session-ID disclosure channel was found.
- The repository does not show a production integration that deliberately selects a predictable session ID.

#### Dataflow

Known session_id -\> global mapping lookup -\> attacker text replacement -\> plaintext response.

- **Source:** Stored token-to-value map

- **Sink:** Unauthenticated /restore response

- **Outcome:** Session plaintext disclosure or mapping poisoning

#### Reachability

The route is reachable on loopback by default.

- **Attacker:** Local caller

- **Entry point:** POST /restore

Preconditions:
- Victim uses the standalone reusable API.
- Attacker learns or influences the session ID.

#### Severity

**Low** — Disclosure is possible after a session identifier is learned or fixed, but generated IDs are UUID4, the default listener is loopback, and proxied Responses sessions are neither exposed nor reusable.

Additional runtime or deployment evidence could raise or lower this severity.

Impact assessment:
- **Level:** high
- **Rationale:** Mapped secrets and PII can be recovered.

Likelihood assessment:
- **Level:** low
- **Rationale:** UUID4 prevents blind guessing and no default disclosure path is shown.

#### Remediation

Remove arbitrary client-selected session identifiers. Generate high-entropy server-side capabilities, bind mappings to an authenticated local principal and independent per-install/client secret, require that credential on protect and restore, and enforce mapping quotas, short TTLs, one-shot restoration, and deletion after use. Prefer removing the standalone restoration API from production and keeping mappings request-scoped inside /responses.

Tests:
- Verify one client cannot reuse or restore another client's session.
- Verify sessions expire and are deleted after restoration.
- Assert supplied session IDs are rejected or replaced by server-generated capabilities.
- Assert one client cannot restore another client's mapping even with the mapping ID.
- Assert sessions expire, are one-shot where applicable, and predictable GP_\* enumeration reveals nothing across principals.

Preventive controls:
- Authenticated session capabilities
- TTL and one-time use
- Server-generated capabilities
- Principal-bound session ownership
- Short TTL and one-shot restore
- Removal or authentication of helper routes

<a id="finding-8"></a>

### [8] Fixed Presidio overlap can miss long entities at chunk boundaries

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | medium |
| Confidence rationale | The windowing gap is explicit, but exact behavior for every long recognizer entity was not executed. The boundary algorithm is explicit; exact behavior depends on the configured recognizer. |
| Category | anonymization-boundary-bypass |
| CWE | CWE-693, CWE-201, CWE-200 |
| Affected lines | privacy-service/proxy.py:170-240, analyzer-config.yaml:51-55, privacy-service/proxy.py:170-244, analyzer-config.yaml:51-55, privacy-service/proxy.py:170-204, privacy-service/proxy.py:225-240 |

#### Summary

Presidio uses 4,000-character cores with only 256 characters of overlap and assigns each result by start position. A complete detection seen in the next overlapped window can be discarded when the entity began in the previous core, while the owning prior scan may have seen only a truncated entity; no supported maximum entity length or stitching rule closes the gap.

#### Root Cause

Chunk overlap is a hardcoded constant unrelated to supported entity lengths, and span ownership does not prove that the detector saw the full entity.

**Fixed scan overlap** — `privacy-service/proxy.py:170-188`

Entities longer than the overlap need not be fully visible in either owning window.

```python
chunk_size = 4000
overlap = 256
...
scan_start = max(0, core_start - overlap)
scan_end = min(len(text), core_end + overlap)
```

**Span ownership uses only start** — `privacy-service/proxy.py:231-240`

There is no complete-visibility check or cross-window stitching.

```python
absolute_start = chunk["scan_start"] + span["start"]
absolute_end = chunk["scan_start"] + span["end"]
if chunk["core_start"] <= absolute_start < chunk["core_end"]:
    mapped.append({...})
```

**Fixed overlap with start-owned result filtering** — `privacy-service/proxy.py:170-187`

The owning chunk cannot see more than 256 characters to the right of its core.

```python
async def scan_presidio_unique(slots):
    chunk_size = 4000
    overlap = 256
...
for core_start in range(0, len(text), chunk_size):
    core_end = min(len(text), core_start + chunk_size)
    scan_start = max(0, core_start - overlap)
    scan_end = min(len(text), core_end + overlap)
```

**Complete next-window result can be rejected** — `privacy-service/proxy.py:228-240`

A full detection in the next overlapped window is discarded if the entity began in the previous core, even when the previous scan saw only a truncated entity.

```python
for span in spans:
    absolute_start = chunk["scan_start"] + span["start"]
    absolute_end = chunk["scan_start"] + span["end"]
    if chunk["core_start"] <= absolute_start < chunk["core_end"]:
        mapped.append({
            **span,
            "start": absolute_start,
            "end": absolute_end,
        })
```

**Overlap is fixed at 256 characters** — `privacy-service/proxy.py:170-199`

Window size is unrelated to supported entity length.

```python
chunk_size = 4000
overlap = 256
...
scan_start = max(0, core_start - overlap)
scan_end = min(len(text), core_end + overlap)
```

**Only the start-containing core owns a span** — `privacy-service/proxy.py:228-240`

A later chunk with better context rejects a span starting in the preceding core.

```python
absolute_start = chunk["scan_start"] + span["start"]
absolute_end = chunk["scan_start"] + span["end"]
if chunk["core_start"] <= absolute_start < chunk["core_end"]:
    mapped.append({...})
```

#### Validation

The code cannot guarantee coverage for an entity extending more than 256 characters across a core boundary.

Validation method: Offline algorithm review

- **Status:** confirmed-with-prerequisite

**Fixed overlap with start-owned result filtering** — `privacy-service/proxy.py:170-187`

The owning chunk cannot see more than 256 characters to the right of its core.

```python
async def scan_presidio_unique(slots):
    chunk_size = 4000
    overlap = 256
...
for core_start in range(0, len(text), chunk_size):
    core_end = min(len(text), core_start + chunk_size)
    scan_start = max(0, core_start - overlap)
    scan_end = min(len(text), core_end + overlap)
```

**Complete next-window result can be rejected** — `privacy-service/proxy.py:228-240`

A full detection in the next overlapped window is discarded if the entity began in the previous core, even when the previous scan saw only a truncated entity.

```python
for span in spans:
    absolute_start = chunk["scan_start"] + span["start"]
    absolute_end = chunk["scan_start"] + span["end"]
    if chunk["core_start"] <= absolute_start < chunk["core_end"]:
        mapped.append({
            **span,
            "start": absolute_start,
            "end": absolute_end,
        })
```

**Overlap is fixed at 256 characters** — `privacy-service/proxy.py:170-199`

Window size is unrelated to supported entity length.

```python
chunk_size = 4000
overlap = 256
...
scan_start = max(0, core_start - overlap)
scan_end = min(len(text), core_end + overlap)
```

**Only the start-containing core owns a span** — `privacy-service/proxy.py:228-240`

A later chunk with better context rejects a span starting in the preceding core.

```python
absolute_start = chunk["scan_start"] + span["start"]
absolute_end = chunk["scan_start"] + span["end"]
if chunk["core_start"] <= absolute_start < chunk["core_end"]:
    mapped.append({...})
```

Assertions:
- No entity-length cap exists.
- No boundary rescan or stitching exists.
- Presidio receives each slot independently.
- Nosey Parker receives two newline characters between slots.
- Only spans wholly contained in one slot are applied.
- Presidio accepts results only when the start belongs to the current core.
- Presidio accepts a result only when its start belongs to the current core.
- A complete next-window result can therefore be rejected even when the prior owning scan lacked full right context.

Counterevidence and remaining uncertainty:
- Shorter entities fit in the overlap.
- Nosey Parker independently scans a larger corpus.
- Ordinary values wholly contained in one string are covered by both detector paths.
- The 256-character overlap covers common short emails, phone numbers, IPs, and names.
- Nosey Parker scans the complete separated corpus and independently catches supported secret formats contained within a slot.
- Common identifiers are shorter than 256 characters.
- Nosey Parker may independently protect some forms.

Limitations:
- No analyzer runtime test was allowed.
- The long-entity subcase depends on configured detector recognition behavior for entities exceeding the overlap; cross-slot fragmentation does not.
- Recognizer-specific behavior was not executed.

#### Dataflow

Long string -\> overlapping Presidio chunks -\> incomplete/ignored span -\> raw tail or entity upstream.

- **Source:** Long sensitive entity

- **Sink:** External request body

- **Outcome:** Partial or full disclosure

Transformations:
- Collect strings as independent slots.
- Insert separators for the Nosey Parker corpus.
- Scan Presidio slots in fixed-overlap chunks.
- Drop cross-slot spans and results whose starts are outside the current core.
- Apply only retained spans and forward all remaining text.

**Fixed overlap with start-owned result filtering** — `privacy-service/proxy.py:170-187`

The owning chunk cannot see more than 256 characters to the right of its core.

```python
async def scan_presidio_unique(slots):
    chunk_size = 4000
    overlap = 256
...
for core_start in range(0, len(text), chunk_size):
    core_end = min(len(text), core_start + chunk_size)
    scan_start = max(0, core_start - overlap)
    scan_end = min(len(text), core_end + overlap)
```

**Complete next-window result can be rejected** — `privacy-service/proxy.py:228-240`

A full detection in the next overlapped window is discarded if the entity began in the previous core, even when the previous scan saw only a truncated entity.

```python
for span in spans:
    absolute_start = chunk["scan_start"] + span["start"]
    absolute_end = chunk["scan_start"] + span["end"]
    if chunk["core_start"] <= absolute_start < chunk["core_end"]:
        mapped.append({
            **span,
            "start": absolute_start,
            "end": absolute_end,
        })
```

#### Reachability

The request model imposes no input length or entity length limit.

- **Attacker:** Request content producer

- **Entry point:** Any scanned input string

Preconditions:
- Entity length exceeds overlap and crosses a core boundary.
- The alternate detector does not catch the value.
- For cross-slot bypass, the sensitive value is split so each fragment evades independent recognition while the upstream receives the ordered fragments.
- For long-chunk bypass, a recognized entity crosses a 4000-character core boundary by more than the 256-character overlap.

Existing controls:
- Dual Nosey Parker and Presidio detection
- Fixed 256-character Presidio overlap
- Fail-closed behavior on detector exceptions

**Fixed overlap with start-owned result filtering** — `privacy-service/proxy.py:170-187`

The owning chunk cannot see more than 256 characters to the right of its core.

```python
async def scan_presidio_unique(slots):
    chunk_size = 4000
    overlap = 256
...
for core_start in range(0, len(text), chunk_size):
    core_end = min(len(text), core_start + chunk_size)
    scan_start = max(0, core_start - overlap)
    scan_end = min(len(text), core_end + overlap)
```

**Complete next-window result can be rejected** — `privacy-service/proxy.py:228-240`

A full detection in the next overlapped window is discarded if the entity began in the previous core, even when the previous scan saw only a truncated entity.

```python
for span in spans:
    absolute_start = chunk["scan_start"] + span["start"]
    absolute_end = chunk["scan_start"] + span["end"]
    if chunk["core_start"] <= absolute_start < chunk["core_end"]:
        mapped.append({
            **span,
            "start": absolute_start,
            "end": absolute_end,
        })
```

#### Severity

**Low** — A long sensitive entity can be exposed, but positioning and detector behavior make the likelihood low.

Additional runtime or deployment evidence could raise or lower this severity.

Impact assessment:
- **Level:** high
- **Rationale:** The exposed portion may include a private signed URL or PII.

Likelihood assessment:
- **Level:** low
- **Rationale:** Requires a long entity, boundary placement, and a detector-specific miss.

#### Remediation

Enforce a supported maximum entity length and derive overlap from it, or implement boundary span stitching/full rescans. Accept a span only after confirming the complete entity was visible.

Tests:
- Test entities around each 4,000-character boundary with lengths below, equal to, and above 256.
- Verify long signed URLs are fully redacted.
- Split known email, API-key, account-number, and signed-URL fixtures at every character position across adjacent valid input items.
- Place long recognizer fixtures at every position around 4000-character boundaries and vary entity length beyond 256 characters.
- Assert that every contributing raw fragment is absent from the serialized upstream payload.
- Verify separate, semantically unrelated fields do not create false-positive cross-field matches.
- Place long signed URLs at every offset around 4,000-character boundaries.
- Assert boundary-touching candidates are rescanned or rejected.

Preventive controls:
- Entity-length invariant
- Boundary-aware rescanning
- Boundary-aware canonicalization
- Reversible cross-slot offset mapping
- Adaptive overlap for boundary-touching detections
- Adversarial fragmentation regression suite
- Boundary-aware chunking
- Recognizer-length budgets
- Fail-closed boundary handling

<a id="finding-9"></a>

### [9] Detector cache preserves stale false negatives across security updates

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | high |
| Confidence rationale | The key construction and cache-hit bypass are explicit and the cache is persisted across rebuilds. |
| Category | stale-security-decision-cache |
| CWE | CWE-693 |
| Affected lines | privacy-service/proxy.py:47-68, privacy-service/proxy.py:184-221, docker-compose.yml:48-49 |

#### Summary

Presidio cache keys contain only a text hash and constant prefix, omitting language, analyzer configuration, model, recognizer, threshold, and version identities, so old misses remain authoritative after detector changes.

#### Root Cause

A privacy decision is cached without all inputs that determine that decision and without TTL or negative-result revalidation.

**Security-decision key omits detector identity** — `privacy-service/proxy.py:188-202`

A hit prevents use of the current analyzer regardless of changed model or policy.

```python
chunk_text = text[scan_start:scan_end]
chunk_hash = hashlib.sha256(chunk_text.encode("utf-8")).hexdigest()
cache_key = "chunk-v1:" + chunk_hash
hit = cache_key in PRESIDIO_CACHE
...
if not hit:
    missing_chunks[cache_key] = chunk_text
```

#### Validation

An empty or incomplete cached span list is reused after any analyzer/configuration change as long as the text is identical.

Validation method: Offline cache dataflow review

- **Status:** confirmed

Assertions:
- The key is only chunk-v1 plus text SHA-256.
- The host volume persists the cache.

Counterevidence and remaining uncertainty:
- Changing the literal chunk-v1 would invalidate entries manually.
- Modified text naturally hashes differently.

Limitations:
- No historical detector update was reproduced.

#### Dataflow

Old scan miss -\> persistent text-only cache -\> new request hit -\> detector skipped -\> raw value upstream.

- **Source:** Cached empty/incomplete spans

- **Sink:** Outbound protected payload

- **Outcome:** Persistent anonymization bypass

#### Reachability

Any repeated text chunk uses the cache across container rebuilds.

- **Attacker:** Content producer relying on a previously cached miss

- **Entry point:** Repeated payload.input text

Preconditions:
- The exact chunk was cached under a weaker detector result.

#### Severity

**Low** — A stale miss can disclose PII, but exploitation requires the exact text to have been cached under an older or weaker detector state.

Additional runtime or deployment evidence could raise or lower this severity.

Impact assessment:
- **Level:** high
- **Rationale:** PII may remain unredacted despite a deployed security improvement.

Likelihood assessment:
- **Level:** low
- **Rationale:** Requires an exact prior cache entry with a material false negative.

#### Remediation

Include language, configuration hash, immutable model/artifact digests, recognizer versions, thresholds, and application version in the key; discard the cache on mismatch, impose TTL/size bounds, and avoid caching negative detections.

Tests:
- Change analyzer fingerprint after caching an empty result and verify the text is rescanned.
- Verify cache invalidation on language, threshold, recognizer, or model changes.

Preventive controls:
- Security-decision cache versioning
- Negative-result revalidation

<a id="finding-10"></a>

### [10] Overlap resolution discards sensitive outer ranges instead of preserving their union

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | medium |
| Confidence rationale | The overlap algorithm's behavior is certain, but no detector runtime was executed to demonstrate a concrete nested-span value in this scan. The interval algorithm is definitive, but exact overlap pairs depend on runtime detector outputs that were not executed. |
| Category | sensitive-data-exposure |
| CWE | CWE-200, CWE-201 |
| Affected lines | privacy-service/app.py:128-150, privacy-service/proxy.py:339-355, analyzer-config.yaml:51-55, privacy-service/proxy.py:341-355, analyzer-config.yaml:51-55, privacy-service/proxy.py:341-355, analyzer-config.yaml:51-55 |

#### Summary

When two detectors return overlapping spans, the lower-priority span is dropped in full, leaving its non-overlapping sensitive prefix or suffix unredacted before the request is forwarded. The resolver prioritizes every Nosey Parker span and discards any overlapping Presidio span instead of protecting the union of all sensitive ranges.

#### Root Cause

Overlap handling chooses one complete detector result by priority instead of computing the union of all characters classified as sensitive. Entity-label priority is incorrectly coupled to coverage; the algorithm chooses one label and also throws away the rest of the sensitive interval.

**Any overlap rejects the entire later candidate** — `privacy-service/app.py:128-150`

The uncovered portion of a lower-priority sensitive range is not merged or retained.

```python
for candidate in spans:
    overlaps = any(
        candidate["start"] < existing["end"]
        and candidate["end"] > existing["start"]
        for existing in selected
    )
    if not overlaps:
        selected.append(candidate)
```

**Resolved spans determine all replacements** — `privacy-service/proxy.py:339-355`

No later union or second-pass control covers discarded characters.

```python
spans = resolve_overlaps(secrets_by_slot.get(index, []) + pii_by_text.get(text, []))
replacements.append(apply_spans(text, spans, session))
```

**Overlapping candidates are discarded instead of merged** — `privacy-service/app.py:128-150`

A shorter high-priority secret span suppresses every broader overlapping range, leaving its unselected characters untouched.

```python
spans = sorted(
    spans,
    key=lambda x: (
        0 if x["source"] == "noseyparker" else 1,
        -x["score"],
        -(x["end"] - x["start"]),
    ),
)

selected = []

for candidate in spans:
    overlaps = any(
        candidate["start"] < existing["end"]
        and candidate["end"] > existing["start"]
        for existing in selected
    )

    if not overlaps:
        selected.append(candidate)
```

**Partial overlap drops the full candidate** — `privacy-service/app.py:128-150`

The resolver neither unions connected sensitive ranges nor retains an uncovered remainder.

```python
spans = sorted(spans, key=lambda x: (
 0 if x["source"] == "noseyparker" else 1,
 -x["score"], -(x["end"] - x["start"]),
))
...
if not overlaps:
    selected.append(candidate)
```

#### Validation

For spans \[a,b\] and \[c,d\] with a\<c\<b\<d, the second candidate is entirely omitted, so \[b,d\] remains in the forwarded text. The configured URL detector makes secret-inside-URL overlap a plausible production case. Whenever a high-priority secret span is contained in or partially overlaps a broader PII span, only the selected interval is replaced and the remaining broader range is forwarded.

Validation method: offline algorithm and caller review

- **Status:** validated-with-runtime-prerequisite

**Any overlap rejects the entire later candidate** — `privacy-service/app.py:128-150`

The uncovered portion of a lower-priority sensitive range is not merged or retained.

```python
for candidate in spans:
    overlaps = any(
        candidate["start"] < existing["end"]
        and candidate["end"] > existing["start"]
        for existing in selected
    )
    if not overlaps:
        selected.append(candidate)
```

**Resolved spans determine all replacements** — `privacy-service/proxy.py:339-355`

No later union or second-pass control covers discarded characters.

```python
spans = resolve_overlaps(secrets_by_slot.get(index, []) + pii_by_text.get(text, []))
replacements.append(apply_spans(text, spans, session))
```

**Partial overlap drops the full candidate** — `privacy-service/app.py:128-150`

The resolver neither unions connected sensitive ranges nor retains an uncovered remainder.

```python
spans = sorted(spans, key=lambda x: (
 0 if x["source"] == "noseyparker" else 1,
 -x["score"], -(x["end"] - x["start"]),
))
...
if not overlaps:
    selected.append(candidate)
```

Assertions:
- Both standalone /protect and /responses use the same resolver.
- No post-replacement detector pass exists.
- Nosey Parker spans always sort before Presidio spans.
- Any overlap rejects the entire later candidate.
- No interval-union step exists.

Counterevidence and remaining uncertainty:
- The selected inner span remains redacted.
- Actual detector co-occurrence was not reproduced.
- The inner secret itself is still tokenized.
- Impact depends on the surrounding unselected characters being sensitive.
- The prioritized secret remains tokenized.
- Confidentiality of the surrounding range is content-dependent.

Limitations:
- Detector output for a concrete payload is deployment/model dependent.
- Detector outputs were not executed to capture a concrete overlapping sample.
- Detector runtime was not executed for a concrete pair.

#### Dataflow

Nosey Parker and Presidio spans enter resolve_overlaps, one overlapping candidate is discarded, apply_spans replaces only selected ranges, and the residual text crosses to the upstream. Credential-bearing URL or broader PII -\> inner secret plus outer detector spans -\> outer span discarded -\> partial plaintext upstream.

- **Source:** Caller-controlled input text Caller-controlled text

- **Sink:** UPSTREAM_BASE/responses

- **Outcome:** Non-overlapping portions of a detector-classified sensitive value remain plaintext. Surrounding sensitive context remains visible

Transformations:
- Independent detection
- priority sort
- whole-span overlap rejection
- partial token replacement

**Any overlap rejects the entire later candidate** — `privacy-service/app.py:128-150`

The uncovered portion of a lower-priority sensitive range is not merged or retained.

```python
for candidate in spans:
    overlaps = any(
        candidate["start"] < existing["end"]
        and candidate["end"] > existing["start"]
        for existing in selected
    )
    if not overlaps:
        selected.append(candidate)
```

**Resolved spans determine all replacements** — `privacy-service/proxy.py:339-355`

No later union or second-pass control covers discarded characters.

```python
spans = resolve_overlaps(secrets_by_slot.get(index, []) + pii_by_text.get(text, []))
replacements.append(apply_spans(text, spans, session))
```

#### Reachability

Reachable whenever detectors return partially overlapping or nested spans; no additional control recomputes union coverage. Reachable when configured detectors emit overlapping ranges, such as a secret inside a recognized URL.

- **Attacker:** Caller or untrusted content shaping a detector overlap Caller controlling request text

- **Entry point:** POST /protect or POST /responses

- **Sink:** Protected output or remote request Protected output or remote upstream request

- **Outcome:** Partial anonymization bypass

Preconditions:
- Detectors return overlapping spans with unique outer coverage.
- Two detectors emit overlapping spans and the discarded range covers additional sensitive characters.

#### Severity

**Low** — The source establishes partial coverage loss, but practical leakage requires the configured detectors to return nested or partially overlapping spans for the submitted value. The inner higher-priority secret remains redacted, while surrounding internal URLs, identifiers, or PII may leak. The selected inner secret remains protected, while additional URL or PII context is exposed only for inputs that produce a broader overlapping detector result.

Severity rises where the discarded outer range routinely contains high-value tenant, host, account, or personal context.

Impact assessment:
- **Level:** medium
- **Rationale:** Internal hosts, paths, account identifiers, or personal context may remain exposed.

Likelihood assessment:
- **Level:** low
- **Rationale:** Requires a qualifying overlap and context-sensitive outer data.

#### Remediation

Compute the union of all sensitive character coverage or split lower-priority spans around already selected ranges. Preserve priority only for entity labeling/token identity, never by dropping characters classified as sensitive. Optionally run a bounded post-replacement invariant check. Merge all overlapping sensitive intervals and protect their full union. Select the placeholder entity label independently from the replacement boundaries, and test containment plus partial-overlap cases such as credentials inside URLs.

Tests:
- Inject synthetic nested and partially overlapping Nosey Parker/Presidio spans and assert the union of all sensitive indices is removed.
- Add detector integration cases for credentials embedded in URLs and identifiers embedded in larger PII spans.
- Feed nested and partially overlapping spans into resolve_overlaps and assert the returned coverage equals their union.
- Test credential-bearing URLs and confirm host, path, query, and credential portions are all protected.
- Test a fake token embedded in a private URL.
- Test partial, nested, and equal overlaps from both sources.

Preventive controls:
- Union-based range coverage
- Post-redaction coverage invariant
- Synthetic overlap regression tests
- Interval-union normalization
- Separate coverage and labeling decisions
- Interval-union redaction
- Cross-detector overlap tests

<a id="finding-11"></a>

### [11] Mutable privacy-critical dependencies can execute while processing raw prompts

| Field | Value |
| --- | --- |
| Severity | low |
| Confidence | high |
| Confidence rationale | Mutable dependency selection and the raw-text analyzer dataflow are explicit in the Dockerfile and application source; malicious upstream publication is the stated prerequisite. Mutable resolution and plaintext processing are certain; malicious content and runtime retrieval behavior were not verified. Mutable image, unconstrained pip install, automatic build, and raw-text analyzer call are explicit. |
| Category | dependency-integrity |
| CWE | CWE-494, CWE-829, CWE-1104 |
| Affected lines | Dockerfile.analyzer:1-4, analyzer-config.yaml:17-25, privacy-service/app.py:100-105, Dockerfile.analyzer:1-4, privacy-service/Dockerfile:1-15, privacy-service/app.py:100-106, analyzer-config.yaml:15-25, scripts/install.ps1:11-18, privacy-service/app.py:100-106, scripts/install.ps1:11-18, privacy-service/app.py:100-105, docker-compose.yml:4-20 |

#### Summary

The analyzer is built from a floating latest image and installs GLiNER without a version or integrity constraint; other privacy-service build inputs also use mutable tags. A compromised or malicious upstream artifact selected on a later build can execute on the plaintext privacy path. The analyzer build uses a latest base image and unversioned gliner package, while runtime configuration names a mutable model; these components receive original secrets before anonymization.

#### Root Cause

Privacy-critical executable artifacts are selected by mutable names without complete digest, hash, signature, or provenance verification, including the analyzer that receives raw prompt fragments. Code and model inputs trusted with raw secrets are selected by mutable names without digest, version, hash, or signature enforcement.

**Floating analyzer image and package** — `Dockerfile.analyzer:1-4`

Neither the base artifact nor GLiNER package is pinned to an immutable digest/version and verified hash.

```dockerfile
FROM ghcr.io/data-privacy-stack/presidio-analyzer:latest

USER root
RUN pip install --no-cache-dir gliner
```

**Analyzer receives original text** — `privacy-service/app.py:100-105`

The mutable analyzer component processes plaintext before local replacement.

```python
response = await client.post(
    f"{PRESIDIO_URL}/analyze",
    json={"text": text, "language": language},
)
```

**Mutable analyzer dependencies** — `Dockerfile.analyzer:1-4`

Neither the image content nor the installed package artifact is immutably selected or integrity checked.

```dockerfile
FROM ghcr.io/data-privacy-stack/presidio-analyzer:latest

USER root
RUN pip install --no-cache-dir gliner
```

**Analyzer receives raw text** — `privacy-service/app.py:100-106`

Substituted analyzer code sees the values before anonymization.

```python
response = await client.post(
    f"{PRESIDIO_URL}/analyze",
    json={"text": text, "language": language},
)
response.raise_for_status()
```

**Analyzer executes mutable image and package inputs** — `Dockerfile.analyzer:1-4`

Neither the image nor the Python package is pinned to an immutable verified artifact.

```dockerfile
FROM ghcr.io/data-privacy-stack/presidio-analyzer:latest

USER root
RUN pip install --no-cache-dir gliner
```

**Original text is sent to the analyzer** — `privacy-service/app.py:100-106`

A compromised analyzer dependency can read every value before replacement.

```python
async def presidio_spans(text: str, language: str):
    async with httpx.AsyncClient(timeout=120) as client:
        response = await client.post(
            f"{PRESIDIO_URL}/analyze",
            json={"text": text, "language": language},
        )
        response.raise_for_status()
```

**Analyzer receives originals** — `privacy-service/app.py:100-105`

Substituted analyzer code sees raw text before tokenization.

```python
response = await client.post(
 f"{PRESIDIO_URL}/analyze",
 json={"text": text, "language": language},
)
```

**Install builds mutable analyzer** — `scripts/install.ps1:11-18`

Normal installation resolves and executes mutable dependencies.

```powershell
if (Test-PrivacyStackHealthy) {
 ...
} else {
 Invoke-Compose @("build")
 Invoke-Compose @("up", "-d")
}
```

#### Validation

Source validation confirms mutable artifact consumption and raw-data access. Exploitation requires a compromised or malicious upstream dependency release. The build and runtime trust mutable external artifacts that sit inside the plaintext boundary; compromise would permit direct capture or detector manipulation.

Validation method: Static Docker build and analyzer dataflow review.

- **Status:** validated-with-prerequisite

**Floating analyzer image and package** — `Dockerfile.analyzer:1-4`

Neither the base artifact nor GLiNER package is pinned to an immutable digest/version and verified hash.

```dockerfile
FROM ghcr.io/data-privacy-stack/presidio-analyzer:latest

USER root
RUN pip install --no-cache-dir gliner
```

**Analyzer receives original text** — `privacy-service/app.py:100-105`

The mutable analyzer component processes plaintext before local replacement.

```python
response = await client.post(
    f"{PRESIDIO_URL}/analyze",
    json={"text": text, "language": language},
)
```

**Analyzer executes mutable image and package inputs** — `Dockerfile.analyzer:1-4`

Neither the image nor the Python package is pinned to an immutable verified artifact.

```dockerfile
FROM ghcr.io/data-privacy-stack/presidio-analyzer:latest

USER root
RUN pip install --no-cache-dir gliner
```

**Analyzer receives originals** — `privacy-service/app.py:100-105`

Substituted analyzer code sees raw text before tokenization.

```python
response = await client.post(
 f"{PRESIDIO_URL}/analyze",
 json={"text": text, "language": language},
)
```

**Install builds mutable analyzer** — `scripts/install.ps1:11-18`

Normal installation resolves and executes mutable dependencies.

```powershell
if (Test-PrivacyStackHealthy) {
 ...
} else {
 Invoke-Compose @("build")
 Invoke-Compose @("up", "-d")
}
```

Assertions:
- latest can resolve to different analyzer image contents over time.
- pip install gliner selects an unconstrained package release.
- The resulting analyzer receives raw request text.
- presidio-analyzer uses latest.
- gliner is unversioned and unhashed.
- The base image tag is latest.
- gliner is installed without a version or hash.
- The configured model is referenced by name rather than immutable revision.
- The analyzer receives raw input text.

Counterevidence and remaining uncertainty:
- The default registries and package are not shown compromised.
- Other privacy-service Python dependencies are exact-version pinned.
- Container isolation limits host impact, but does not protect raw prompts delivered to the analyzer.
- Nosey Parker and Python use version tags.
- Python requirements use exact versions.
- No Docker socket is mounted.
- Nosey Parker and Python use version tags, Python requirements use exact versions, and no Docker socket is mounted; tags and exact versions still do not provide immutable artifact identity by themselves.
- One independent worker treated mutable analyzer artifacts as a hardening concern rather than a current-state exploit absent compromise of a registry, package, image, or model source.
- No actual artifact compromise is established.
- The analyzer configuration volume is read-only.
- The Nosey Parker image and privacy-service Python packages use version tags or exact versions, though not all are digest/hash pinned.
- privacy-service packages are version-pinned.
- Nosey Parker uses a version tag.
- No analyzer digest, gliner lock, hash, or signature check exists.

Limitations:
- No external registry state, signatures, SBOM, or build attestations were inspected.
- Dependency contents and registry state were not fetched or assessed.
- No registry, package, image, or model compromise was observed or tested.
- Dependency provenance, model download timing, signatures, and container egress were not inspected at runtime.
- No current malicious dependency was alleged or fetched.

#### Dataflow

Mutable registry/package reference -\> container build/runtime code -\> raw analyzer request text. Mutable registry/package/model resolution -\> analyzer code executes -\> raw prompt sent to /analyze -\> capture, exfiltration, or false-negative response.

Attack steps:
- Compromise or publish a malicious artifact under a mutable analyzer image or GLiNER package reference.
- Cause a user or automation to rebuild the stack.
- The malicious code executes in the analyzer image.
- Raw prompt fragments arrive at /analyze before anonymization.

- **Source:** Public image/Python package registries External mutable dependency distribution

- **Sink:** Analyzer processing of plaintext prompt fragments Analyzer process handling plaintext

- **Outcome:** Potential prompt disclosure or malicious build/runtime execution. Privacy bypass or secret exfiltration

Transformations:
- Docker image resolution
- pip package installation
- container execution

**Floating analyzer image and package** — `Dockerfile.analyzer:1-4`

Neither the base artifact nor GLiNER package is pinned to an immutable digest/version and verified hash.

```dockerfile
FROM ghcr.io/data-privacy-stack/presidio-analyzer:latest

USER root
RUN pip install --no-cache-dir gliner
```

**Analyzer receives original text** — `privacy-service/app.py:100-105`

The mutable analyzer component processes plaintext before local replacement.

```python
response = await client.post(
    f"{PRESIDIO_URL}/analyze",
    json={"text": text, "language": language},
)
```

#### Reachability

Reachable on any rebuild that resolves a malicious mutable artifact. Conditional on compromise of a referenced distribution source during build or model resolution.

- **Attacker:** Compromised registry/package publisher or account Registry, package-index, or model-repository supply-chain attacker

- **Entry point:** Dockerfile.analyzer build docker compose build or analyzer model resolution

- **Sink:** Presidio analyzer receiving raw text Plaintext analyzer

- **Outcome:** Supply-chain compromise of the privacy boundary. All analyzed secrets exposed or detector results subverted

Preconditions:
- A rebuild resolves the mutable reference after upstream compromise or malicious publication.
- A malicious upstream artifact is available when the image is rebuilt.
- The build/runtime can access the external registry as normally required.
- A mutable external artifact is malicious or compromised.

Existing controls:
- Container boundary
- Some other application dependencies are version-pinned

#### Severity

**Low** — Compromise would expose high-impact data and execute build/runtime code, but exploitation requires compromise or malicious publication in a trusted external registry/package account. A compromise has high confidentiality impact, but exploitation requires control of an external registry, package index, or model distribution source and no current compromise is established. Compromise completely defeats confidentiality but requires external artifact compromise or mutation.

Severity increases if builds automatically consume updates in production or the build environment has additional credentials and network privileges. Severity rises upon evidence of a compromised artifact, weak build-network trust, or broad analyzer egress in a sensitive deployment.

Impact assessment:
- **Level:** high
- **Rationale:** Compromised analyzer code sees every raw analyzed fragment and can execute in the container. The analyzer sees original secrets and can alter every detection decision.

Likelihood assessment:
- **Level:** low
- **Rationale:** Requires external dependency supply-chain compromise. Requires an external supply-chain compromise not evidenced in this snapshot.

#### Remediation

Pin every privacy-critical image by an approved immutable sha256 digest. Hash-lock GLiNER and all Python/transitive artifacts, build from an approved mirror, verify signatures and attestations, generate and compare an SBOM, run detector components as non-root, and restrict analyzer egress so compromised detector code cannot transmit plaintext. Rebuild only through a controlled update process with privacy-boundary regression tests. Pin every container by digest, lock gliner and transitive Python dependencies with versions and hashes, pin the model to an immutable revision with checksum verification, distribute signed images from a controlled registry, and block unnecessary analyzer egress.

Tests:
- Fail CI if any FROM reference uses latest or lacks the approved digest.
- Install Python dependencies with require-hashes from a locked file and verify an altered artifact is rejected.
- Generate and compare an SBOM/attestation for release images before deployment.
- Fail builds when image digests or package hashes do not match an approved lock.
- Verify analyzer runs non-root and cannot reach external networks.
- Fail builds for any unapproved tag-only image reference or package lacking an approved hash.
- Verify the analyzer runs non-root and cannot reach unauthorized external networks.
- Fail builds when image digests, package hashes, or model revisions differ from the approved lock.
- Verify the analyzer starts and detects canaries with outbound network access disabled.
- Record and validate signed provenance for built images.
- Fail build on unexpected digest or lock changes.
- Verify analyzer has no unnecessary outbound network route.

Preventive controls:
- Immutable image digests
- Hash-locked dependencies
- Signed provenance and SBOM verification
- Controlled dependency update workflow
- Immutable dependency locks
- Provenance verification
- Detector egress restriction
- Immutable digests and hash-locked dependencies
- Signed build provenance
- Pinned model revision
- Analyzer egress restriction
- Digest pinning
- Hashed lock

## Reviewed Surfaces

| Surface | Risk Area | Outcome | Notes |
| --- | --- | --- | --- |
| Responses body, query, header, schema, traversal, detector dispatch, and outbound serialization Responses request traversal and outbound anonymization | Confidentiality and anonymization bypass Sensitive data exposure | Reported | Top-level non-input fields, global nested-key and tools exclusions, unsupported shapes, and forwarded query/nonfiltered-header values were reduced into one complete-outbound-policy finding; deliberate authorization forwarding and administrator-controlled destinations remain explicit counterevidence. Reviewed complete request forwarding, top-level fields, recursive slot collection, skipped keys, skipped subtrees, and fail-closed detector behavior. Top-level, skipped-key, tools-subtree, non-string, and cross-slot representations were traced to the upstream sink. |
| Cross-slot and fixed-overlap detector coverage | Protection mechanism bypass | Reported | Cross-slot fragmentation and the long-entity fixed-overlap gap remain separate because canonical seam scanning does not by itself fix incomplete long-entity visibility. Runtime detector behavior remains a prerequisite for concrete examples. Reviewed Presidio per-slot scans, Nosey Parker combined corpus, offset mapping, fixed overlaps, result ownership, and strongest counterevidence. |
| Detector offset mapping, overlap resolution, and replacement coverage | Partial sensitive-range exposure | Reported | Whole-span priority rejection can leave the unique outer portion of an overlapping sensitive range raw; detector co-occurrence was not executed. |
| Streaming placeholder restoration and downstream control fields | Integrity, output injection, and secondary disclosure unsafe-output-rewriting | Reported | Transport and UTF-8 split handling were reviewed; successful streams are restored without SSE/JSON field classification. Downstream execution remains an external prerequisite. Reviewed UTF-8 chunk handling, token-prefix buffering, JSON escaping, token collision behavior, SSE/JSON context, and request-scoped cleanup. Whole-stream restoration can place originals into outbound-exempt identifiers. |
| Loopback proxy identity, readiness, and OAuth forwarding | Credential and prompt theft | Reported | HTTP 200 readiness does not authenticate the local service that receives OAuth-bearing Codex requests; default loopback exposure and port ownership are prerequisites. |
| Standalone protect/restore ownership, fixation, lifetime, and guessing | Broken object authorization and retained plaintext | Reported | Caller-selected known/fixed IDs can cross client boundaries. Blind guessing of server-generated UUIDv4 IDs and internal /responses sessions remains rejected. |
| Local admission, body parsing, detector work, subprocesses, sessions, and persistent cache lifecycle | Availability and retained plaintext | Reported | Unbounded work, subprocess time, session retention, cache growth, and full cache rewrites are grouped under one resource-invariant failure; default loopback binding lowers severity. Reviewed both /protect and /responses, body and semantic limits, authorization timing, subprocess deadlines, analyzer timeouts, and loopback exposure. Reviewed manual and proxied sessions, cleanup paths, raw mapping retention, cache keys, persistence, and absence of capacity policies. |
| Detector cache validity across language, model, recognizer, threshold, configuration, and version changes | Stale privacy decisions | Reported | Persistent text-only keys can reuse old false negatives after a security update. |
| Codex provider installation, TOML scope, backup/uninstall behavior, and effective-config verification | Privacy routing bypass | Reported | Section-blind model_provider rewriting and doctor checks can leave the effective global provider outside the proxy; array-bound commands and scoped destructive paths produced no separate injection or traversal issue. |
| Configured upstream/analyzer destinations, redirects, SSRF, smuggling, and credential routing | Request and credential routing | No issue found | Service destinations are administrator-controlled and the shipped upstream is HTTPS; no request-controlled destination, concrete smuggling path, or separate lower-privilege configuration attacker was established. No request-controlled upstream destination, cross-client OAuth theft, or blind session enumeration was established. Default publication is loopback; broader binding is recorded as a prerequisite where relevant. |
| Container, Python package, detector model, image provenance, privilege, mounts, and raw-data access | Build integrity and raw-prompt confidentiality | Reported | Mutable latest, unpinned GLiNER, and other tag-only build inputs reach privacy-critical code. Exploitation requires compromised or malicious upstream artifacts. No lower-privilege source-to-sink exploit was established. Mutable analyzer artifacts are a hardening concern, not reported as an exploitable current-state vulnerability without registry or package compromise evidence. |
| PowerShell bootstrap, lifecycle, packaging, filesystem changes, and wrappers | Command injection, path safety, and destructive operations | No issue found | Arguments are array-bound or fixed and destructive targets are scoped; configuration scope confusion is separately reported. |
| Documentation, integration guidance, demos, regression assertions, and inactive recognizer reference configuration | Operational assumptions and preventive controls | No issue found | The active analyzer configuration is analyzer-config.yaml; recognizers.yaml is not mounted. Existing tests omit reported adversarial body shapes, seams, overlap unions, and context-aware restoration. No production credential was present. Test tokens are synthetic; packaging excludes .env and runtime cache JSON; documentation preserves the local-only default. |
| SQL/NoSQL injection, XSS, SSRF, XXE, uploads, unsafe deserialization, traversal, command injection, and memory safety | Common application vulnerability classes | Not applicable | No applicable in-scope sink was established; Nosey Parker input uses stdin and command arguments are arrays. Nosey Parker uses a fixed argv and stdin without a shell; no path traversal, unsafe deserialization, request-smuggling, or response-splitting path was established. |
| Detector failure handling, upstream errors, response cleanup, and internal session deletion | Preventive controls | No issue found | Covered input detector failures return 503 before send, upstream errors are not restored, and internal /responses sessions are normally removed on terminal paths. |
| Responses request envelope and outbound privacy boundary | Sensitive-data exposure | Reported | Reviewed parsing, field selection, header forwarding, fail-closed behavior, and upstream serialization. |
| Nested input traversal, skipped keys, tools, media, and opaque content | Anonymization coverage | Reported | No additional canonical notes were recorded. |
| Nosey Parker and Presidio span mapping, chunking, language, caching, and overlap resolution | Detection completeness | Reported | No additional canonical notes were recorded. |
| Placeholder generation and streaming/non-streaming restoration | Response integrity and secret replay | Reported | No additional canonical notes were recorded. |
| Protect/restore session ownership, secrecy, cleanup, and lifecycle | State retention and availability | Reported | No additional canonical notes were recorded. |
| Request sizes, detector concurrency, subprocess timeouts, persistent cache, and streaming Request, scanner, session, cache, and persistence resource governance | Denial of service Availability | Reported | Both manual and proxied paths were reviewed and combined under one missing-budget control. |
| Loopback publication, upstream routing, forwarded authorization, and response headers | Credential routing | No issue found | Defaults use loopback and the expected HTTPS upstream. Operator-controlled endpoint changes were treated as privileged configuration rather than standalone remote vulnerabilities. |
| PowerShell installation, Codex config mutation, command execution, packaging, and deletion | Local code execution and configuration integrity | No issue found | No attacker-controlled shell interpolation, unsafe broad deletion, or independent privilege-boundary violation was established. |
| Container privileges, images, Python packages, model references, volumes, and health checks | Supply-chain integrity | Reported | No additional canonical notes were recorded. |
| README, integration guides, recognizer reference, and regression coverage | Security expectations and counterevidence | No issue found | Documentation confirms text anonymization intent, default loopback binding, and synthetic test credentials; tests omit the reported bypass cases. |
| Streaming placeholder restoration and downstream active fields | Secret injection | Reported | Raw response replacement reaches all protocol fields; JSON escaping and downstream approval were assessed as countercontrols. |
| Codex provider credential channel and local endpoint identity | Credential theft | Reported | Default loopback constraints and port-ownership prerequisites were included in severity. |
| Detector overlap, chunking, UTF-8 offsets, and language handling | Sensitive data exposure | Rejected | Cross-slot mapping was reported separately. A larger overlapping-span remainder and spans longer than the configured overlap are plausible, but exact external detector outputs were not established from current source. |
| Manual protect/restore session confidentiality and ownership | Broken access control | No issue found | UUIDv4 prevents blind guessing; caller-selected identifiers and unauthenticated restore remain hardening concerns without a source-backed path for forcing a victim to use a known identifier. |
| PowerShell command invocation, environment parsing, TOML mutation, project trust, and lifecycle cleanup | Local privilege and configuration integrity | No issue found | No command injection or new privilege boundary was established. Config writes are backed up but non-atomic. |
| Container image, Python dependency, and model provenance Container and dependency supply-chain integrity | Supply chain supply-chain-integrity | Reported | Mutable latest and unpinned analyzer dependencies are material hardening gaps, but no current malicious artifact or compromised publisher was established and that attacker was outside the supplied context. Analyzer image and gliner dependency are mutable. |
| Documentation, regression coverage, examples, packaging, and ignored runtime state | Operational safety | No issue found | Existing tests do not cover retained anonymization findings, but no separate vulnerability was found in packaging or documentation behavior. |
| Responses request field classification and anonymization | sensitive-data-exposure | Reported | Top-level and exempt-key bypasses validated. |
| Detector slot, chunk, offset, and overlap handling | privacy-filter-bypass | Reported | Cross-slot, overlap-union, and boundary gaps validated with prerequisites. |
| Session, cache, request, and detector resource lifecycle | resource-exhaustion | Reported | Default exposure is loopback; severity was downgraded. |
| Network routing, header forwarding, and SSRF boundaries | network-security | No issue found | Destinations are configuration-controlled and default ports bind loopback. |
| PowerShell installer, packaging, and Codex configuration lifecycle | local-code-execution | No issue found | No attacker-controlled command or path reached execution. |
| Injection, upload, database, deserialization, browser, and memory-safety classes | general-application-security | Not applicable | No applicable database, upload, HTML, unsafe-deserialization, native-memory, or request-controlled filesystem sink. |
| Documentation, regression tests, examples, and packaging | assurance | No issue found | Tests omit the reported bypass variants. |

## Open Questions And Follow Up

- How do the pinned Presidio recognizers behave for entities longer than the 256-character overlap at 4,000-character boundaries?
  - Follow-up prompt: Run boundary tests against the exact pinned analyzer and preserve both partial and complete detector spans.
- Which concrete detector outputs produce nested or partially overlapping ranges with unique outer sensitive coverage?
  - Follow-up prompt: Add synthetic union tests, then run representative secret-in-URL and identifier-in-PII cases.
- Which optional top-level Responses fields, query parameters, forwarded headers, and structured tool-result shapes are emitted by deployed clients?
  - Follow-up prompt: Capture sanitized request schemas and add outbound canary tests without collecting real prompts.
- Which restored response fields can trigger automatic or approved downstream tools, URL fetches, logs, or exports?
  - Follow-up prompt: Test fake placeholders under the deployed client approval policy.
- Why do prior worker inventory records differ between 29 explicitly listed files and 31 reported in-scope files?
  - Follow-up prompt: Reconcile the inventory from authoritative scan receipts without inspecting outside the authorized scope.
- Has PROXY_BIND_HOST changed from the source default?
  - Follow-up prompt: Verify the effective bind without disclosing environment secrets and raise resource-exhaustion severity if the service is network-exposed.
- Source establishes a fixed 256-character overlap without a supported entity-length invariant, but exact recognizer behavior for representative long entities was not executed.
  - Follow-up prompt: Review deferred unit presidio-long-entity-overlap and close its stated proof gap.
- The union-loss algorithm is established statically, but concrete co-occurring Nosey Parker and Presidio spans depend on runtime detector/model output.
  - Follow-up prompt: Review deferred unit detector-overlap-cooccurrence and close its stated proof gap.
- The repository does not define the deployed client's tool execution, URL fetching, logging, or approval behavior.
  - Follow-up prompt: Review deferred unit downstream-restoration-consumers and close its stated proof gap.
- No live sanitized capture establishes which optional Responses fields and structured tool-result shapes deployed clients populate.
  - Follow-up prompt: Review deferred unit deployed-request-shapes and close its stated proof gap.
- The previous aggregate records a discrepancy between a 29-file explicit inventory and two workers reporting 31 in-scope files; the reducer did not inspect repository code.
  - Follow-up prompt: Review deferred unit scope-inventory-reconciliation and close its stated proof gap.
