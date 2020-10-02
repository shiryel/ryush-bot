defmodule RyushDiscord.Guild.Talk do
  @moduledoc """
  Process messages that occur on a Talk

  It'll close the talk after 10 minutes of no new messages

  ## Processes
  - `RyushDiscord.Guild.Talk.TalkRegistry` registry the servers that are open
  - `RyushDiscord.Guild.Talk.TalkSupervisor` a dynamic supervisor for the servers
  - `RyushDiscord.Guild.Talk.TalkServer` the guild servers
  """
  require Logger

  alias RyushDiscord.Guild
  alias __MODULE__.{TalkRegistry, TalkServer, TalkSupervisor}

  @type about :: :continue_talk | :start | :e621

  @doc """
  Get the server name

  Used to create and find the guild servers through the `RyushDiscord.Guild.GuildRegistry`
  """
  @spec get_server_name(Guild.t()) :: {:via, Registry, {TalkRegistry, {binary, binary}}}
  def get_server_name(guild) do
    {:via, Registry, {TalkRegistry, {guild.channel_id, guild.user_id}}}
  end

  @doc """
  See if the talk exists on registry
  """
  @spec talk_exists?(%Guild{}) :: true | false
  def talk_exists?(guild) do
    case Registry.lookup(TalkRegistry, {guild.channel_id, guild.user_id}) do
      [] ->
        false

      _ ->
        true
    end
  end

  @doc """
  Starts a new `RyushDiscord.Guild.Talk.TalkServer`
  """
  @spec start_new_talk(Guild.t(), about()) :: DynamicSupervisor.on_start_child()
  def start_new_talk(guild, about) do
    DynamicSupervisor.start_child(TalkSupervisor, {TalkServer, guild: guild, about: about})
  end

  @doc """
  Process a `RyushDiscord.Guild.t()` with they `about()`

  When the `about` is `:continue_talk`, if the server is closed, returns false, otherwise returns true, signaling that the talk still occuring
  """
  @spec process(Guild.t(), GuildServer.t(), about()) :: boolean()
  def process(guild, guild_state, :continue_talk) do
    if talk_exists?(guild) do
      GenServer.cast(get_server_name(guild), {:process, :continue_talk, guild, guild_state})
      true
    else
      false
    end
  end

  def process(guild, guild_state, about) do
    if talk_exists?(guild) do
      GenServer.cast(get_server_name(guild), {:process, about, guild, guild_state})
      true
    else
      Logger.info("Starting new talk: #{inspect(about)}")
      start_new_talk(guild, about)
      GenServer.cast(get_server_name(guild), {:process, about, guild, guild_state})
      true
    end
  end
end
