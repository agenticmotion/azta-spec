package azta.policy.mcp.zendesk

import future.keywords.in
import data.azta.policy.common

default allow = false
default require_hitl = false

# Rule 1: Deny if input parameter contains indirect prompt injection
deny[reason] {
    some param_name, param_value in input.tool_execution.parameters
    is_string(param_value)
    common.has_prompt_injection(param_value)
    reason := sprintf("PROMPT_INJECTION_DETECTED: Parameter '%s' contains hostile prompt override signature.", [param_name])
}

# Rule 2: Deny if user scope lacks ticket update privileges
deny[reason] {
    input.tool_execution.function_name in ["update_ticket_status", "add_ticket_comment"]
    not "zendesk.tickets.write" in input.initiating_user.delegated_scopes
    reason := "SCOPE_VIOLATION: User delegated scope lacks 'zendesk.tickets.write'."
}

# Rule 3: Flag High-Impact Actions for Human-In-The-Loop (HITL) Review
require_hitl {
    input.tool_execution.function_name in ["delete_ticket", "bulk_close_tickets", "export_user_data"]
}

# Rule 4: Global Allow Decision
allow {
    count(deny) == 0
    not require_hitl
}
