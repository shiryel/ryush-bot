defmodule RyushDiscord.Guild.Talk.TalkServer do
  @moduledoc """
  Conversations that happens on a talk, the talk is a `{channel_id, user_id}` from the guild
  """
  @enforce_keys ~w|talking_about|a
  defstruct talking_about: nil,
            step: 0

  use GenServer

  require Logger

  alias RyushDiscord.Guild
  alias Guild.Talk
  alias Talk.Flows

  # Used by the `RyushDiscord.Talk.DynamicSupervisor` with Guilds
  def start_link(guild: guild, about: about) do
    GenServer.start_link(__MODULE__, %__MODULE__{talking_about: about},
      name: Talk.get_server_name(guild)
    )
  end

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:process, :continue_talk, guild, guild_state}, state) do
    process(state.talking_about, guild, guild_state, state)
  end

  def handle_cast({:process, about, guild, guild_state}, state) do
    process(about, guild, guild_state, state)
  end

  ###########
  # PROCESS #
  ###########

  defp process(about, guild, guild_state, state) do
    case about do
      :start ->
        Flows.Start.run(guild, guild_state, state)
      not_handled ->
        Logger.error("Talk flow not handled: #{not_handled}")
    end
  end
end
