defmodule Fanoutpages.Repo do
  use Ecto.Repo,
    otp_app: :fanoutpages,
    adapter: Ecto.Adapters.Postgres
end
