# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk do
  @moduledoc """
  Process messages that occur on a Talk

  It'll close the talk after 10 minutes of no new messages

  ## Processes
  - `RyushDiscord.GuildTalk.TalkRegistry` registry the servers that are open
  - `RyushDiscord.GuildTalk.TalkSupervisor` a dynamic supervisor for the servers
  - `RyushDiscord.GuildTalk.TalkServer` the guild servers
  """
  require Logger

  alias RyushDiscord.Guild
  alias __MODULE__.{TalkRegistry}

  @doc """
  Process a `RyushDiscord.Guild.t()` with they `about()`

  When the `about` is `:continue_talk`, if the server is closed, returns false, otherwise returns true, signaling that the talk still occuring
  """
  @spec process(Guild.t(), Guild.GuildServer.t(), atom()) ::
          {:ok, Guild.GuildServer.t()} | {:error, :talk_not_found}
  def process(%{is_myself?: true} = guild, guild_state, :continue_talk) do
    if TalkRegistry.exists?(guild.channel_id, guild_state.last_message_user_id) do
      response =
        GenServer.call(
          TalkRegistry.get_name(guild.channel_id, guild_state.last_message_user_id),
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

      DynamicSupervisor.start_child(
        RyushDiscord.GuildSupervisor,
        {__MODULE__.TalkServer, guild: guild, about: about}
      )

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
