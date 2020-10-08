defmodule RyushDiscord.Talk.TalkServer do
  @moduledoc """
  Conversations that happens on a talk, the talk is a `{channel_id, user_id}` from the guild
  """
  @enforce_keys ~w|talking_about|a
  defstruct talking_about: nil,
            step: :start,
            cache: []

  use GenServer, restart: :transient

  require Logger

  alias RyushDiscord.{Flow, Talk}
  alias Talk.TalkRegistry

  # Used by the `RyushDiscord.Talk.DynamicSupervisor` with Guilds
  def start_link(guild: guild, about: about) do
    GenServer.start_link(__MODULE__, %__MODULE__{talking_about: about},
      name: TalkRegistry.get_name(guild)
    )
  end

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    Logger.debug("Starting new talk\n state: #{inspect(state)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:process, :continue_talk, guild, guild_state}, _from, state) do
    process(state.talking_about, guild, guild_state, state)
  end

  def handle_call({:process, about, guild, guild_state}, _from, state) do
    process(about, guild, guild_state, state)
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating Talk\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end

  ###########
  # PROCESS #
  ###########

  defp process(about, guild, guild_state, state) do
    case about do
      :start ->
        apply(Flow.Start, String.to_atom("_paw_" <> Atom.to_string(state.step) <> "_"), [guild, guild_state, state])
        |> abstraction()

      :e621 ->
        apply(Flow.E621, String.to_atom("_paw_" <> Atom.to_string(state.step) <> "_"), [guild, guild_state, state])
        |> abstraction()

      not_handled ->
        Logger.error("Talk flow not handled: #{not_handled}")
    end
  end

  defp abstraction({:stop, guild_state, state}) do
    {:stop, :normal, guild_state, state}
  end

  defp abstraction({next_step, guild_state, state}) do
    {:reply, guild_state, %{state | step: next_step}}
  end
end
