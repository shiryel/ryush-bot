# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildFlow.FlowBehaviour do
  @moduledoc """
  Creates a GenServer with default functions to `start/1` `stop/1` `exists?/1`

  This functions are used extensively by the `RyushDiscord.Talk` submodules when they need to manipulate a `RyushDiscord.Flow`
  """

  @callback start_link(options :: term()) :: GenServer.on_start()

  @callback on_restart() :: :ok

  defmacro __using__(_opts) do
    quote do
      @behaviour RyushDiscord.GuildFlow.FlowBehaviour

      use GenServer, restart: :transient

      alias RyushDiscord.{Guild, GuildFlow}
      alias GuildFlow.{FlowRegistry, FlowSupervisor}

      @doc """
      Starts the `#{__MODULE__}` server with the options that are specific to the server struct
      """
      @spec start(map()) :: DynamicSupervisor.on_start_child
      def start(options) do
        DynamicSupervisor.start_child(RyushDiscord.GuildSupervisor, {__MODULE__, [struct: options, new: true]})
      end

      @doc """
      Start from the DB, changing the options `:new` to `:false`
      """
      @spec start_from_db(map()) :: DynamicSupervisor.on_start_child
      def start_from_db(options) do
        DynamicSupervisor.start_child(RyushDiscord.GuildSupervisor, {__MODULE__, [struct: options, new: false]})
      end

      @doc """
      Stops the `#{__MODULE__}` server with the guild param
      """
      @spec stop(Guild.t) :: :ok
      def stop(guild) do
        GenServer.stop(get_server_name(guild), :normal)
      end

      @doc """
      Verify if the `#{__MODULE__}` server exists
      """
      @spec exists?(Guild.t) :: boolean
      def exists?(guild) do
        FlowRegistry.exists?(__MODULE__, guild)
      end

      defp get_server_name(%Guild{} = guild) do
        {:via, Registry, {FlowRegistry, {__MODULE__, guild.channel_id}}}
      end

      defp get_server_name(channel_id) do
        {:via, Registry, {FlowRegistry, {__MODULE__, channel_id}}}
      end
    end
  end
end
