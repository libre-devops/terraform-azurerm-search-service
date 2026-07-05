# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated. They are the place to enforce module-wide consistency.

# The module does nothing without at least one search service.
check "has_services" {
  assert {
    condition     = length(var.search_services) > 0
    error_message = "No search_services were supplied, so this module creates nothing."
  }
}

# The secure baseline is no public endpoint. If public access is on, warn unless there is an
# allowed_ips allow-list narrowing it down.
check "public_access_is_locked_down" {
  assert {
    condition = alltrue([
      for s in values(var.search_services) :
      s.public_network_access_enabled == false || length(s.allowed_ips) > 0
    ])
    error_message = "A search service has the public endpoint enabled with no allowed_ips allow-list, so it is reachable from any network. Prefer public_network_access_enabled = false with a private endpoint, or set allowed_ips."
  }
}

# Entra-only auth is the secure posture; warn when API keys are left on.
check "prefer_entra_only_auth" {
  assert {
    condition = alltrue([
      for s in values(var.search_services) : s.local_authentication_enabled == false
    ])
    error_message = "A search service has local_authentication_enabled = true (admin and query API keys work). Prefer Entra ID / RBAC (local_authentication_enabled = false) and grant data-plane roles instead."
  }
}
