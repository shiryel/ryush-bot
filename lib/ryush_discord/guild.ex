# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

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
            emoji: nil,
            message_id: nil,
            username: nil,
            user_id: nil,
            user_role_ids: [],
            channel_id: nil,
            guild_id: nil,
            permissions: nil

  @type t :: %__MODULE__{
          bot_token: binary(),
          mentions_me?: boolean(),
          is_myself?: boolean(),
          message: binary() | nil,
          emoji: %{id: binary(), name: binary()} | nil,
          message_id: binary(),
          username: binary(),
          user_id: binary(),
          user_role_ids: [String.t()],
          channel_id: binary(),
          guild_id: binary(),
          permissions: __MODULE__.Permissions.t() | nil
        }

  require Logger

  alias __MODULE__.{GuildRegistry, GuildServer}

  @doc """
  Process a `RyushDiscord.Guild.t()`

  If the server is not open, opens it and then process
  """
  @spec process(t()) :: :ok
  def process(msg) do
    server_name = GuildServer.get_server_name(msg)

    if GuildRegistry.exists?(msg) do
      GenServer.cast(server_name, {:process, msg})
    else
      Logger.info("starting new guild #{msg.guild_id}...")
      DynamicSupervisor.start_child(RyushDiscord.GuildSupervisor, {GuildServer, msg: msg})
      GenServer.cast(server_name, {:process, msg})
    end
  end
end
