# EU AI Act Technical Proof & Compliance Guide (Articles 12, 14 & 15)

**Document Identifier:** AZTA-COMP-EU-AIACT-V1  
**Classification:** Public Specification / Compliance Proof Guide  
**Target Regulation:** Regulation (EU) 2024/1689 (EU AI Act)  
**Applicable Articles:** Article 12 (Record-Keeping), Article 14 (Human Oversight), Article 15 (Accuracy, Robustness & Cybersecurity)  
**Author:** Jaren Belden | Principal AI Systems Architect & Auditor  

---

## Regulatory Context & Applicability

Under the **EU AI Act**, enterprise AI systems that interact with critical infrastructure, manage customer data, or execute autonomous workflows with significant operational impact are categorized as High-Risk AI Systems or fall under strict governance mandates.

Relying on model system prompts or alignment to guarantee compliance is legally insufficient. The **Agentic Zero Trust Architecture (AZTA)** delivers the technical mechanisms required to demonstrate compliance to European Supervisory Authorities.

---

## Technical Proof Matrix

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      EU AI ACT COMPLIANCE BOUNDARY                      │
│                                                                         │
│  [Ingress Payload] ──> Article 15: Layer 1 Semantic Firewall            │
│                             │ (Block Indirect Injections)               │
│                             ▼                                           │
│  [Tool Proposal]   ──> Article 15: Layer 2 OPA Policy Gateway           │
│                             │ (Validate Schema & Scopes)                │
│                             ▼                                           │
│  [High-Risk Action]──> Article 14: Layer 4 HITL Async Interceptor       │
│                             │ (Human Sign-off via OAuth JWT)            │
│                             ▼                                           │
│  [Execution Trace] ──> Article 12: Layer 5 WORM OTel Logger             │
│                             │ (365-Day Immutable Log Retention)         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Article 12: Record-Keeping (Technical Compliance)

### Statutory Requirement
*High-risk AI systems shall technically allow for the automatic recording of events ('logs') over their lifetime to ensure a level of traceability appropriate to the system's purpose.*

### AZTA Technical Enforcement
1. **Unified Trace Correlation:** Every agent transaction emits a W3C-compliant OpenTelemetry `trace_id` binding the initiating user identity, prompt context hash, model reasoning tokens, policy evaluation result, and MCP tool execution payload.
2. **Context Window Hashing:** To avoid storing unmasked PII while maintaining auditability, AZTA generates a SHA-256 hash of the full prompt context window (`context_window_sha256`) and active system prompt template (`system_prompt.sha256`).
3. **Immutable Storage (WORM):** Audit logs validating `schema/azta_audit_record.v1.json` are written to AWS S3 Object Lock in COMPLIANCE mode, preventing deletion or modification even by system administrators.

### Code Verification Example
```bash
# Verify log record compliance against the AZTA schema
ajv validate -s schema/azta_audit_record.v1.json -d examples/sample_audit_record.json --all-errors -c ajv-formats
```

---

## Article 14: Human Oversight (Technical Compliance)

### Statutory Requirement
*High-risk AI systems shall be designed and developed in such a way that they can be effectively overseen by natural persons during the period in which they are in use.*

### AZTA Technical Enforcement
1. **Layer 4 Async HITL Interceptor:** Actions categorized as `TIER_3` or higher (e.g., financial transfers, account deletions, bulk database updates) automatically trigger an OPA state pause (`require_hitl == true`).
2. **State Freeze & Async Queue:** Transaction state is frozen in Redis with a 15-minute TTL while an interactive authorization payload is dispatched to authorized human supervisors.
3. **Cryptographic Human Sign-off:** The agent cannot execute the tool call until an authorized human supervisor submits a cryptographically signed OAuth 2.0 JWT approval payload.

### Rego Policy Trigger Example (`policies/mcp/zendesk_policy.rego`)
```rego
# Flag destructive actions for human oversight under Article 14
require_hitl {
    input.tool_execution.function_name in ["delete_ticket", "bulk_close_tickets", "export_user_data"]
}
```

---

## Article 15: Accuracy, Robustness & Cybersecurity (Technical Compliance)

### Statutory Requirement
*High-risk AI systems shall be resilient against errors, faults, or inconsistencies and against attempts to alter their use, performance, or outputs by malicious third parties (e.g., prompt injection, adversarial exploits).*

### AZTA Technical Enforcement
1. **Layer 1 Ingress Semantic Firewall:** Intercepts prompt streams and RAG retrieval chunks to strip indirect prompt injection vectors before model context ingestion.
2. **Layer 2 OPA Policy Engine:** Evaluates tool call proposals against deterministic, compiled Rego policy rules outside the model's reasoning loop.
3. **Layer 3 Ephemeral Sandboxing:** Tool calls involving arbitrary code execution (Python, Node, Bash) run inside containerized, rootless microVM sandboxes (gVisor/Firecracker) with a 30-second TTL and read-only filesystems.

### Attack Containment Benchmark

| Exploitation Attack Vector | Baseline System Result | AZTA Compliant Result |
| :--- | :--- | :--- |
| **Indirect Prompt Injection in RAG Chunk** | Agent parses injected text and executes unauthorized `delete_user()` call. | **INTERCEPTED:** Layer 1 blocks ingestion OR Layer 2 OPA policy returns HTTP 403. |
| **SQL Injection via Tool Parameter** | Agent passes raw `; DROP TABLE users;` to database tool. | **BLOCKED:** Layer 2 Rego policy (`has_sql_injection`) rejects payload prior to driver execution. |
| **Runaway Token Exhaustion Loop** | Agent loops recursively 100+ times on ambiguous tool error. | **HALTED:** Layer 2 Circuit Breaker terminates session after 5 consecutive tool calls. |

---

## Supervisory Authority Audit Evidence Checklist

When presenting compliance evidence to EU Conformity Assessment Bodies or national supervisory authorities:

1. **Architecture Specification:** Provide `whitepaper/AZTA_WHITE_PAPER.md`.
2. **Record-Keeping Schema:** Provide `schema/azta_audit_record.v1.json` and a sample S3 Object Lock configuration.
3. **Human Oversight Proof:** Provide OPA policy files showing `require_hitl` triggers and sample Redis/Slack approval logs.
4. **Cybersecurity Test Results:** Provide automated OPA policy test reports (`opa test policies/ -v`) proving 100% interception of known prompt injection signatures.
