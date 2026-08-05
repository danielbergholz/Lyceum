import Config

# Copy this file to config/dev.secret.exs and fill in real values.
# config/dev.secret.exs is gitignored and auto-loaded from config/dev.exs.
#
# Lyceum has no third-party secrets wired up yet. Add per-service config here as
# you integrate them, following the commented examples below. Prod reads the same
# values from env vars via config/runtime.exs.

# Transactional email. Dev defaults to Swoosh.Adapters.Local so messages land in
# http://localhost:4000/dev/mailbox — override the adapter here only when you
# need to test real delivery.
# config :lyceum, Lyceum.Mailer,
#   adapter: Swoosh.Adapters.Resend,
#   api_key: "re_dev_xxx"
#
# config :swoosh, :api_client, Swoosh.ApiClient.Req
