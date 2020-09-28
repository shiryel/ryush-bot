defmodule Ryush.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias RyushDiscord.Connection.GatewayBot

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      #Ryush.Repo,
      # Start the Telemetry supervisor
      RyushWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ryush.PubSub},
      # Start the Endpoint (http/https)
      RyushWeb.Endpoint,
      # Start a worker by calling: Ryush.Worker.start_link(arg)
      # {Ryush.Worker, arg}

      {GatewayBot, bot_token: Application.get_env(:ryush, :bot_token)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ryush.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RyushWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
