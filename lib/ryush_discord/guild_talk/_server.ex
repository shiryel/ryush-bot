# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk.TalkServer do
  @moduledoc """
  Conversations that happens on a talk, the talk is a `{channel_id, user_id}` from the guild
  """
  @enforce_keys ~w|talking_about|a
  defstruct talking_about: nil,
            step: :start,
            cache: nil,
            last_emoji_message_id: nil,
            message_ids: []

  @type t :: %__MODULE__{
          talking_about: atom(),
          step: atom(),
          cache: %{},
          last_emoji_message_id: String.t(),
          message_ids: [String.t()]
        }

  use GenServer, restart: :transient

  require Logger

  alias RyushDiscord.GuildTalk
  alias GuildTalk.TalkRegistry

  # Used by the `RyushDiscord.Talk.DynamicSupervisor` with Guilds
  def start_link(msg: msg, about: about) do
    GenServer.start_link(__MODULE__, %__MODULE__{talking_about: about},
      name: TalkRegistry.get_name(msg)
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
  def handle_call(
        {:process, :continue_talk, %{is_myself?: true} = msg, guild_state},
        _from,
        state
      ) do
    state = %{state | message_ids: [msg.message_id | state.message_ids]}

    {:reply, guild_state, state}
  end

  def handle_call(
        {:process, :continue_talk, %{emoji: %{name: _}} = msg, guild_state},
        _from,
        state
      ) do
    state = %{
      state
      | last_emoji_message_id: msg.message_id,
        message_ids: [msg.message_id | state.message_ids]
    }

    process(state.talking_about, msg, guild_state, state)
  end

  def handle_call({:process, :continue_talk, msg, guild_state}, _from, state) do
    guild_state = %{guild_state | last_message_user_id: msg.user_id}
    state = %{state | message_ids: [msg.message_id | state.message_ids]}

    process(state.talking_about, msg, guild_state, state)
  end

  def handle_call({:process, about, msg, guild_state}, _from, state) do
    guild_state = %{guild_state | last_message_user_id: msg.user_id}
    state = %{state | message_ids: [msg.message_id | state.message_ids]}

    process(about, msg, guild_state, state)
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating Talk\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end

  ###########
  # PROCESS #
  ###########

  defp process(about, msg, guild_state, state) do
    case about do
      #########
      # ADMIN #
      #########
      :change_prefix ->
        GuildTalk.ChangePrefix.paw_run(state.step, msg, guild_state, state)

      :manage_commands ->
        GuildTalk.ManageCommands.paw_run(state.step, msg, guild_state, state)

      :set_notification_channel ->
        GuildTalk.SetNotificationChannel.paw_run(state.step, msg, guild_state, state)

      ###########
      # MANAGED #
      ###########
      :e621 ->
        GuildTalk.E621.paw_run(state.step, msg, guild_state, state)

      ##########
      # ANYONE #
      ##########
      :about ->
        GuildTalk.About.paw_run(state.step, msg, guild_state, state)

      :help ->
        GuildTalk.Help.paw_run(state.step, msg, guild_state, state)

      not_handled ->
        Logger.error("Talk flow not handled: #{not_handled}")
    end
  end
end
