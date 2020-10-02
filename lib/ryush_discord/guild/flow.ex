defmodule RyushDiscord.Guild.Flow do
  @moduledoc """
  Flow servers to keep custom flows working through time
  """

  alias RyushDiscord.Guild
  alias __MODULE__.{FlowRegistry, FlowSupervisor}

  @doc """
  Get the server name

  Used to create and find the flow servers through the `RyushDiscord.Guild.GuildRegistry`
  """
  @spec get_server_name(atom(), Guild.t()) :: {:via, Registry, {FlowRegistry, {binary, binary}}}
  def get_server_name(flow_module, guild) do
    {:via, Registry, {FlowRegistry, {flow_module, guild.channel_id}}}
  end

  @doc """
  See if the flow exists on registry
  """
  @spec flow_exists?(any, %Guild{}) :: true | false
  def flow_exists?(flow_name, guild) do
    case Registry.lookup(FlowRegistry, {flow_name, guild.user_id}) do
      [] ->
        false

      _ ->
        true
    end
  end

  @doc """
  Starts a new flow server
  """
  @spec start_new_server(any) :: DynamicSupervisor.on_start_child()
  def start_new_server(server) do
    DynamicSupervisor.start_child(FlowSupervisor, server)
  end

  def send_cast(flow_module, guild, info) do
    server = get_server_name(flow_module, guild)
    GenServer.cast(server, info)
  end
end
