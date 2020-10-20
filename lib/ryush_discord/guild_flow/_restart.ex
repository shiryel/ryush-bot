# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildFlow.FlowRestart do
  @moduledoc """
  Restart the flows using the `c:RyushDiscord.GuildFlow.FlowBehaviour.on_restart/0` behaviour function
  """

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
