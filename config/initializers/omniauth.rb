# OmniAuth failure handler for API-only mode.
# By default, OmniAuth's FailureApp does a redirect (HTML behavior).
# For API mode, we return JSON 422 instead.
OmniAuth.config.on_failure = proc { |env|
  body = { error: "Autenticação OAuth falhou", code: "oauth_failed" }.to_json
  [422, { "Content-Type" => "application/json" }, [body]]
}

# Allow GET for OAuth initiation — required for SPA + separate Rails API.
# The frontend can't include a Rails CSRF token, so we allow GET here.
# The OAuth flow is protected by the provider's state parameter.
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
