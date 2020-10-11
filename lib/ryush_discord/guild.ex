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

  alias __MODULE__.{GuildRegistry, GuildServer}

  @doc """
  Process a `RyushDiscord.Guild.t()`

  If the server is not open, opens it and then process
  """
  @spec process(t()) :: :ok
  def process(guild) do
    server_name = GuildServer.get_server_name(guild)

    if GuildRegistry.exists?(guild) do
      GenServer.cast(server_name, {:process, guild})
    else
      Logger.info("starting new guild #{guild.guild_id}...")
      DynamicSupervisor.start_child(RyushDiscord.GuildSupervisor, {GuildServer, guild: guild})
      GenServer.cast(server_name, {:process, guild})
    end
  end
end
