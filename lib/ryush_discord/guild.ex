defmodule RyushDiscord.Guild do
  @moduledoc """
  Process messages that occur on a Guild

  If necessary, will use the `RyushDiscord.Guild.Talk` module to create a talk on a specifc channel with only one or multiple users

  ## Processes
  - `RyushDiscord.Guild.GuildRegistry` registry the servers that are open
  - `RyushDiscord.Guild.GuildSupervisor` a dynamic supervisor for the servers
  - `RyushDiscord.Guild.GuildServer` the guild servers
  """
  @enforce_keys ~w|bot_token mentions_me? is_myself? message user_id username channel_id guild_id|a
  defstruct bot_token: nil,
            mentions_me?: false,
            is_myself?: false,
            message: nil,
            username: nil,
            user_id: nil,
            channel_id: nil,
            guild_id: nil

  @type t :: %__MODULE__{
          bot_token: binary(),
          mentions_me?: boolean(),
          is_myself?: boolean(),
          message: binary(),
          username: binary(),
          user_id: binary(),
          channel_id: binary(),
          guild_id: binary()
        }

  require Logger

  alias __MODULE__.{GuildRegistry, GuildServer, GuildSupervisor}
  alias RyushDiscord.Connection.ApiBot

  @doc """
  Get the server name

  Used to create and find the guild servers through the `RyushDiscord.Guild.GuildRegistry`
  """
  @spec get_server_name(t()) :: {:via, Registry, {GuildRegistry, String.t}}
  def get_server_name(guild) do
    {:via, Registry, {GuildRegistry, guild.guild_id}}
  end

  @doc """
  See if the guild exists on `RyushDiscord.Guild.GuildRegistry`
  """
  @spec guild_exists?(t()) :: boolean()
  def guild_exists?(guild) do
    case Registry.lookup(GuildRegistry, guild.guild_id) do
      [] ->
        false
      _ ->
        true
    end
  end

  @doc """
  Starts a new `RyushDiscord.Guild.GenServer`
  """
  @spec start_new_guild(t()) :: DynamicSupervisor.on_start_child()
  def start_new_guild(guild) do
    DynamicSupervisor.start_child(GuildSupervisor, {GuildServer, guild: guild})
  end

  @doc """
  Process a `RyushDiscord.Guild.t()`

  If the server is not open, opens it and then process
  """
  @spec process(t()) :: :ok
  def process(guild) do
    if guild_exists?(guild) do
      GenServer.cast(get_server_name(guild), {:process, guild})
    else
      Logger.info("starting new guild #{guild.guild_id}")
      start_new_guild(guild)
      GenServer.cast(get_server_name(guild), {:process, guild})
    end
  end

  @doc """
  Send text in the channel
  """
  @spec say_text(binary(), t()) :: :ok
  def say_text(text, guild) do
    body =
      %{
        content: text
      }

    ApiBot.create_message(guild.channel_id, body, guild.bot_token)
  end

  @doc """
  Updates the current message handler that the bot in the guilds uses to get commands

  WARNING: This function when used outside the `RyushDiscord.Guild.GuildServer` process can lead to race-conditions, use this with caution
  """
  @spec update_guild_state(t(), GuildServer.t) :: :ok
  def update_guild_state(guild, guild_state) do
    GenServer.cast(get_server_name(guild), {:update_guild_state, guild_state})
  end
end
