# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ryush,
  ecto_repos: [Ryush.Repo]

config :mnesia,
  dir: 'mnesia_db'

# Configures the endpoint
config :ryush, RyushWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "knh+oTsXOnqVEWfKa9BVpXo1HJURp93HeAxGEFPcGfWr7w2j+FtIbgPLV7KNserI",
  render_errors: [view: RyushWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Ryush.PubSub,
  live_view: [signing_salt: "nOOffGCE"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
