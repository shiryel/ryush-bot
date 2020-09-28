defmodule Ryush.Repo do
  use Ecto.Repo,
    otp_app: :ryush,
    adapter: Ecto.Adapters.Postgres
end
