defmodule RyushDiscord.Talk do
  @moduledoc """
  Process messages that occur on a Talk

  It'll close the talk after 10 minutes of no new messages

  ## Processes
  - `RyushDiscord.Talk.TalkRegistry` registry the servers that are open
  - `RyushDiscord.Talk.TalkSupervisor` a dynamic supervisor for the servers
  - `RyushDiscord.Talk.TalkServer` the guild servers
  """
  require Logger

  alias RyushDiscord.Guild
  alias __MODULE__.{TalkRegistry, TalkSupervisor}

  @doc """
  Process a `RyushDiscord.Guild.t()` with they `about()`

  When the `about` is `:continue_talk`, if the server is closed, returns false, otherwise returns true, signaling that the talk still occuring
  """
  @spec process(Guild.t(), Guild.GuildServer.t(), atom()) ::
          {:ok, Guild.GuildServer.t()} | {:error, :talk_not_found}
  def process(guild, guild_state, :continue_talk) do
    if TalkRegistry.exists?(guild) do
      response =
        GenServer.call(
          TalkRegistry.get_name(guild),
          {:process, :continue_talk, guild, guild_state}
        )

      {:ok, response}
    else
      {:error, :talk_not_found}
    end
  catch
    :exit, _ ->
      Logger.warn("Talk server timeout")
      {:ok, guild_state}
  end

  def process(guild, guild_state, about) do
    if TalkRegistry.exists?(guild) do
      response =
        GenServer.call(TalkRegistry.get_name(guild), {:process, about, guild, guild_state})

      {:ok, response}
    else
      Logger.info("Starting new talk: #{inspect(about)}")
      TalkSupervisor.start_new(guild, about)

      response =
        GenServer.call(TalkRegistry.get_name(guild), {:process, about, guild, guild_state})

      {:ok, response}
    end
  catch
    :exit, _ ->
      Logger.warn("Talk server timeout")
      {:ok, guild_state}
  end
end
