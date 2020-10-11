defmodule RyushDiscord.Guild.GuildServer do
  @moduledoc """
  The guild main controller, will foward some talks to `RyushDiscord.Guild.Talk.TalkServer`

  Uses the default behaviour `RyushDiscord.Guild.ServerProcess`
  """
  defstruct command_prefix: nil,
            admin_channel: nil,
            owner_id: nil

  @type t :: %__MODULE__{command_prefix: binary(), admin_channel: binary(), owner_id: binary()}

  alias RyushDiscord.Guild
  alias Guild.{GuildRegistry, ServerProcess}
  alias :mnesia, as: Mnesia

  require Logger

  use GenServer, restart: :transient

  def start_link(guild: guild) do
    Mnesia.wait_for_tables([__MODULE__], 2000)
    Mnesia.create_table(__MODULE__, []) # defaults the attributes to [key, val]

    state =
      case fn -> Mnesia.read(__MODULE__, guild.guild_id) end |> Mnesia.transaction() do
        {:atomic, [{_, _, %{command_prefix: command_prefix, admin_channel: admin_channel}}]} ->
          Logger.debug("Database found! updating...")
          %__MODULE__{}
          |> Map.put(:command_prefix, command_prefix)
          |> Map.put(:admin_channel, admin_channel)

        _ ->
          Logger.debug("Database not found")
          %__MODULE__{}
      end

    GenServer.start_link(__MODULE__, state, name: get_server_name(guild))
  end

  @doc """
  Get the server name

  Used to create and find the guild servers through the `RyushDiscord.Guild.GuildRegistry`
  """
  def get_server_name(guild) do
    {:via, Registry, {GuildRegistry, guild.guild_id}}
  end

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    Logger.debug("Starting new guild\n state: #{inspect(state)}")
    {:ok, state}
  end

  @impl true
  def handle_cast({:process, guild}, state) do
    ServerProcess.paw_run(:system, :pre_process, guild, state)
  end

  def handle_cast(request, state) do
    Logger.error("cant handle: request |#{inspect(request)}| state |#{inspect(state)}|")

    {:noreply, state}
  end

  @impl true
  def handle_info({:update_db, guild_id}, state) do
    fn ->
      Mnesia.write({__MODULE__, guild_id, state})
    end
    |> Mnesia.transaction()

    Mnesia.dump_tables([__MODULE__])

    Logger.debug("Database #{__MODULE__} updated!")

    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating Guild\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end
end
