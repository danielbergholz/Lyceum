defmodule Lyceum.Repo do
  use Ecto.Repo,
    otp_app: :lyceum,
    adapter: Ecto.Adapters.Postgres
end
