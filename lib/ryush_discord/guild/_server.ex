defmodule RyushDiscord.Guild.GuildServer do
  @moduledoc """
  The guild main controller, will foward some talks to `RyushDiscord.Guild.Talk.TalkServer`

  Uses the default behaviour `RyushDiscord.Guild.ServerProcess`
  """
  defstruct message_handler: nil,
            admin_channel: nil,
            owner_id: nil

  @type t :: %__MODULE__{message_handler: binary(), admin_channel: binary(), owner_id: binary()}

  alias RyushDiscord.Guild
  alias Guild.{GuildRegistry, ServerProcess}

  require Logger

  use GenServer, restart: :transient

  def start_link(guild: guild) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: get_server_name(guild))
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
  def terminate(reason, state) do
    Logger.debug("Terminating Guild\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end
end
