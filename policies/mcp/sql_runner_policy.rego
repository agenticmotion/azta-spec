package azta.policy.mcp.sql_runner

import future.keywords.in
import data.azta.policy.common

default allow = false

# Rule 1: Strictly deny non-SELECT queries
deny[reason] {
    query := input.tool_execution.parameters.query
    common.has_sql_injection(query)
    reason := "DESTRUCTIVE_SQL_BLOCKED: Query contains forbidden DDL/DML mutation syntax."
}

# Rule 2: Enforce Read-Only Scope
deny[reason] {
    not "database.read_only" in input.initiating_user.delegated_scopes
    reason := "SCOPE_VIOLATION: SQL Runner requires explicit 'database.read_only' scope."
}

# Rule 3: Allow only if query starts with SELECT
allow {
    count(deny) == 0
    query := input.tool_execution.parameters.query
    re_match("(?i)^\\s*SELECT\\b", query)
}
