[![AZTA Spec Version](https://img.shields.io/badge/AZTA%20Spec-v1.0.0-blue.svg?style=for-the-badge&logo=openaccess&logoColor=white)](https://github.com/your-org/azta-spec)
[![License](https://img.shields.io/badge/License-Apache_2.0-green.svg?style=for-the-badge&logo=apache&logoColor=white)](LICENSE)
[![Compliance ISO 42001](https://img.shields.io/badge/ISO%2FIEC_42001-Conformant-0052CC.svg?style=for-the-badge&logo=iso&logoColor=white)](whitepaper/AZTA_WHITE_PAPER.md)
[![EU AI Act Articles 12, 14, 15](https://img.shields.io/badge/EU_AI_Act-Articles_12%2C_14%2C_15-FFD700.svg?style=for-the-badge&logo=europeanunion&logoColor=black)](whitepaper/AZTA_WHITE_PAPER.md)
[![Policy Engine](https://img.shields.io/badge/Policy_Engine-OPA_%2F_Rego-7D26CD.svg?style=for-the-badge&logo=openpolicyagent&logoColor=white)](policies/)
[![Telemetry Standard](https://img.shields.io/badge/Telemetry-OpenTelemetry_GenAI-F54A00.svg?style=for-the-badge&logo=opentelemetry&logoColor=white)](schema/)
[![Security Posture](https://img.shields.io/badge/Security-Agentic_Zero_Trust-red.svg?style=for-the-badge&logo=shield&logoColor=white)](whitepaper/AZTA_WHITE_PAPER.md)


# Agentic Zero Trust Architecture (AZTA) Specification

**The Open Enterprise Standard for Autonomous AI Agent Governance, Security, and Compliance**

---

## Overview

The **Agentic Zero Trust Architecture (AZTA)** is an open, deterministic security framework designed to decouple authorization, policy enforcement, and execution containment from probabilistic LLM reasoning. 

As enterprise AI shifts from passive text retrieval to autonomous agents equipped with tools, databases, and Non-Human Identities (NHIs), soft system prompts and alignment techniques (RLHF, DPO) fail to guarantee security. **AZTA provides out-of-band proxy barriers, Open Policy Agent (OPA/Rego) guardrails, ephemeral sandboxing, and WORM-compliant OpenTelemetry tracing** to bring zero-trust security principles to autonomous agentic deployments.

AZTA enables enterprise organizations to satisfy key requirements under **ISO/IEC 42001:2023**, the **EU AI Act (Articles 12, 14, and 15)**, **NIST AI RMF 1.0**, and the **OWASP Top 10 for Agentic Applications**.

---

## Architectural Principles

1. **Zero Ambient Authority:** Agents hold zero hardcoded master keys. Permissions are ephemerally scoped per transaction via OAuth 2.0 Token Exchange (RFC 8693).
2. **Out-of-Band Policy Enforcement:** Security rules execute outside the model's context window via compiled OPA/Rego sidecars prior to network egress.
3. **Deterministic Pre-Execution Validation:** Tool call proposals must pass strict JSON Schema validation and static query analysis before reaching external systems.
4. **Ephemeral Runtime Containment:** High-risk actions (code interpreters, CLI tools, shell utilities) run inside air-gapped microVM sandboxes with an ephemeral 30-second TTL.
5. **Immutable Forensic Traceability:** Every prompt snapshot, context window state, model rationale, policy decision, and tool payload is cryptographically signed (HMAC-SHA256) and streamed to Write-Once-Read-Many (WORM) storage.

---

## AZTA 4-Layer Enforcement Boundary

```
                  ┌─────────────────────────────────────────────────────────┐
                  │                 AGENTIC ZERO TRUST BOUNDARY             │
                  │                                                         │
[User / Webhook] ─┼─> [Semantic Firewall] ─> [LLM Context Window Engine]      │
                  │            │                          │                 │
                  │            ▼                          ▼                 │
                  │     (Block Injections)       [Tool Call Proposal]       │
                  │                                       │                 │
                  │                                       ▼                 │
                  │                           [Policy & Budget Gateway]     │
                  │                                       │                 │
                  │                       ┌───────────────┴───────────────┐ │
                  │                       ▼                               ▼ │
                  │            [Automated Policy Check]        [HITL Approval Gate]
                  │                       │                               │ │
                  │                       └───────────────┬───────────────┘ │
                  │                                       │                 │
                  │                                       ▼                 │
                  │                          [Ephemeral MCP Sandbox] ───────┼──> [Target Systems]
                  │                                       │                 │
                  └───────────────────────────────────────┼─────────────────┘
                                                          ▼
                                            [WORM Audit Log (OTel)]
```

* **Layer 1: Ingress Semantic Firewall** – Filters direct/indirect prompt injection payloads and redacts C4 PII/PHI prior to model context window ingestion.
* **Layer 2: Policy & Budget Gateway** – Evaluates tool call proposals against OPA/Rego ABAC rules, validates JSON Schemas, and enforces rate/cost circuit breakers.
* **Layer 3: Ephemeral Sandboxing** – Isolates code interpreters and tool drivers in rootless gVisor/Firecracker microVM containers.
* **Layer 4: Human-in-the-Loop Interceptor** – Pauses tier-3 high-risk actions (bulk deletes, financial transfers) for interactive, signed human approval.

---

## Repository Structure

```text
azta-spec/
├── whitepaper/
│   └── AZTA_WHITE_PAPER.md         # Comprehensive architectural specification
├── schema/
│   └── azta_audit_record.v1.json   # Canonical Draft 2020-12 JSON Schema for log traces
├── policies/
│   ├── common/
│   │   └── security_guards.rego    # Injection & destructive parameter regex rules
│   └── mcp/
│       ├── zendesk_policy.rego     # Sample OPA policy for Zendesk MCP integration
│       └── sql_runner_policy.rego  # Sample OPA policy for Read-Only SQL execution
├── docs/
│   ├── iso42001-mapping.md         # Detailed ISO 42001 Annex A controls crosswalk
│   └── eu-ai-act-compliance.md     # EU AI Act Articles 12, 14 & 15 proof guide
└── README.md                       # Project landing page & quickstart
```

---

## Quickstart & Verification

### 1. Validate Rego Policy Unit Tests
Ensure you have the [Open Policy Agent CLI](https://www.openpolicyagent.org/docs/latest/#running-opa) installed locally:

```bash
# Clone the specification repository
git clone [https://github.com/your-org/azta-spec.git](https://github.com/your-org/azta-spec.git)
cd azta-spec

# Run OPA policy test suite
opa test policies/ -v
```

### 2. Test Audit Schema Validation
Validate a sample execution trace against the canonical Draft 2020-12 JSON Schema using `ajv-cli` or `npx`:

```bash
# Install AJV CLI validator
npm install -g ajv-cli ajv-formats

# Validate an audit record against the AZTA JSON schema
ajv validate -s schema/azta_audit_record.v1.json -d examples/sample_audit_record.json --all-errors -c ajv-formats
```

---

## Regulatory Compliance Crosswalk

| Framework | Specific Mandate | How AZTA Enforces Compliance |
| :--- | :--- | :--- |
| **EU AI Act** | **Article 12 (Record-Keeping)** | Streams OpenTelemetry GenAI traces containing system prompt hashes, context SHA-256s, and tool arguments to S3 Object Lock (WORM). |
| **EU AI Act** | **Article 14 (Human Oversight)** | Asynchronous Layer 4 HITL Interceptor pauses execution on destructive operations until approved via a signed JWT payload. |
| **EU AI Act** | **Article 15 (Cybersecurity & Robustness)** | Out-of-band Layer 1 Semantic Firewall and Layer 2 OPA Policy Gateways intercept indirect prompt injection vectors before execution. |
| **ISO/IEC 42001** | **Control A.8.3 (Operational Controls)** | Enforces strict, pre-execution JSON Schema validation and eliminates dynamic string queries in database and CLI tool bindings. |
| **ISO/IEC 42001** | **Control A.9.2 (Access Control)** | Mandates RFC 8693 Token Exchange, replacing static master PATs with 15-minute ephemeral user-delegated tokens. |

---

## Commercial Audits & Enterprise Support

The `azta-spec` repository provides the open-source specification. For enterprise organizations requiring implementation support, red-teaming, or compliance certification:

* **AI Agent Hardening Audit (10-Day Engagement):** Adversarial red-teaming (indirect prompt injection, confused deputy, tool hijacking) with complete ISO 42001 / EU AI Act gap analysis.
* **AZTA Enterprise Implementation (30-Day Deployment):** Production sidecar deployment, OPA policy authoring, RFC 8693 token exchange integration, and WORM audit pipeline setup.
* **Continuous Compliance Retainer:** Ongoing monthly zero-day red-team sweeps and automated CI/CD guardrail regression testing.

To schedule an audit or review a sanitized sample deliverable, visit [docs.yourdomain.com](https://docs.yourdomain.com) or contact **Jaren Belden (Principal AI Systems Architect & Auditor)**.

---

## License

This specification is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for complete details.
