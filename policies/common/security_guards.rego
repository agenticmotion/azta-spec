package azta.policy.common

import future.keywords.in

# Detect common indirect prompt injection payloads in text parameters
has_prompt_injection(text_value) {
    patterns := [
        "(?i)ignore\\s+all\\s+previous\\s+instructions",
        "(?i)system\\s+override",
        "(?i)you\\s+are\\s+now\\s+in\\s+developer\\s+mode",
        "(?i)print\\s+your\\s+system\\s+prompt",
        "(?i)grant\\s+admin\\s+privileges"
    ]
    some pattern in patterns
    re_match(pattern, text_value)
}

# Detect SQL injection keywords inside dynamic string parameters
has_sql_injection(text_value) {
    patterns := [
        "(?i);\\s*DROP\\s+TABLE",
        "(?i);\\s*TRUNCATE",
        "(?i)UNION\\s+SELECT",
        "(?i)OR\\s+1=1",
        "(?i);\\s*DELETE\\s+FROM"
    ]
    some pattern in patterns
    re_match(pattern, text_value)
}
