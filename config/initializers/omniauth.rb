# OmniAuth failure handler for API-only mode.
# By default, OmniAuth's FailureApp does a redirect (HTML behavior).
# For API mode, we return JSON 422 instead.
OmniAuth.config.on_failure = proc { |env|
  body = { error: "Autenticação OAuth falhou", code: "oauth_failed" }.to_json
  [422, { "Content-Type" => "application/json" }, [body]]
}
