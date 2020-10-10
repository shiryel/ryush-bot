defmodule RyushDiscord.GuildFlow.FlowRestart do
  alias :mnesia, as: Mnesia
  alias RyushDiscord.GuildFlow

  require Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  def start_link(_opts) do
    Logger.info("Restarting the flows...")

    Task.start_link(fn ->
      GuildFlow.E621.on_restart()
    end)
  end
end
