defmodule RyushDiscord.Guild.GuildServer do
  @moduledoc """
  The guild main controller, will foward some talks to `RyushDiscord.Guild.Talk.TalkServer`
  """
  defstruct message_handler: nil,
            admin_channel: nil

  @type t :: %__MODULE__{message_handler: binary(), admin_channel: binary()}

  use GenServer

  require Logger

  alias RyushDiscord.Guild
  alias Guild.Talk

  def start_link(guild: guild) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: Guild.get_server_name(guild))
  end

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:update_guild_state, new_state}, _state) do
    {:noreply, new_state}
  end

  def handle_cast({:process, guild}, state) do
    process(guild, state)
  end

  def handle_cast(request, state) do
    Logger.error("cant handle: request |#{inspect(request)}| state |#{inspect(state)}|")

    {:noreply, state}
  end

  ###########
  # PROCESS #
  ###########

  # Special cases (like start)
  defp process(%{mentions_me?: true} = guild, state) do
    unless Talk.process(guild, state, :continue_talk) do
      process_mention(guild, state)
    end

    {:noreply, state}
  end

  # Essential configuration (message_handler and admin_channel)
  defp process(
         %{is_myself?: false, message: message} = guild,
         %{message_handler: message_handler, admin_channel: admin_channel} = state
       )
       when is_nil(message_handler) or is_nil(admin_channel) do
    # remove message_handler if exists
    guild =
      if message_handler == nil do
        guild
      else
        %{guild | message: String.replace(message, state.message_handler, "", global: false)}
      end

    Talk.process(guild, state, :continue_talk)

    {:noreply, state}
  end

  #
  # Anothers messages start here
  #
  defp process(%{message: message, is_myself?: false} = guild, state) do
    if String.match?(message, ~r/^#{state.message_handler}[[:alnum:]]+/) do
      guild = %{
        guild
        | message: String.replace(message, state.message_handler, "", global: false)
      }

      Guild.say_text("SCREEEEEEEE", guild)
    end

    {:noreply, state}
  end

  # Default handler
  defp process(guild, state) do
    Logger.warn("Not handled: guild |#{inspect(guild)}| state |#{inspect(state)}|")
    {:noreply, state}
  end

  # [Mention] start
  defp process_mention(%{message: message} = guild, state) do
    if String.contains?(message, "start") do
      Talk.process(guild, state, :start)
    else
      Guild.say_text(
        """
        ```CSS
        *BEEP BOOP*
        ```
        Hello #{guild.username}, My name is Ryush and I need your assistence...
        Lets say that... well...

        Just mention me again with the start command, like this:
        `@Ryush start`
        """,
        guild
      )
    end
  end
end
