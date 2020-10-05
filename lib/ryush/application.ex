defmodule Ryush.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias RyushDiscord.Connection.GatewayBot

  def start(_type, _args) do
    bot_token = Application.get_env(:ryush, :bot_token)
    bot_user_id = Application.get_env(:ryush, :bot_user_id)

    children = [
      # Start the Ecto repository
      #Ryush.Repo,
      # Start the Telemetry supervisor
      RyushWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ryush.PubSub},
      # Start the Endpoint (http/https)
      RyushWeb.Endpoint,
      # Start the Guild Registry and DynamicSupervisor
      RyushDiscord.Guild.GuildRegistry,
      RyushDiscord.Guild.GuildSupervisor,
      # Start the Talk Registry and DynamicSupervisor
      RyushDiscord.Talk.TalkRegistry,
      RyushDiscord.Talk.TalkSupervisor,
      # Start the Flow Registry and DynamicSupervisor
      RyushDiscord.Flow.FlowRegistry,
      RyushDiscord.Flow.FlowSupervisor,
      # Start the Bot Gateway (uses the `RyushDiscord.Guild...`)
      {GatewayBot, bot_token: bot_token, bot_user_id: bot_user_id}
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
