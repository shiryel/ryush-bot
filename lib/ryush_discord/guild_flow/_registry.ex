# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildFlow.FlowRegistry do
  @moduledoc false

  alias RyushDiscord.Guild

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_ignore) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  @doc """
  See if the flow exists on registry
  """
  @spec exists?(any, %Guild{}) :: true | false
  def exists?(flow_module, guild) do
    case Registry.lookup(__MODULE__, {flow_module, guild.channel_id}) do
      [] ->
        false

      _ ->
        true
    end
  end
end
