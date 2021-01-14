# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.Guild.Permissions do
  @moduledoc """
  Handle permissions on a `t:RyushDiscord.Guild.t()`, used on the `RyushDiscord.Guild.ServerProcess`
  """

  defstruct roles: [],
            owner?: false,
            administrator?: false,
            manage_channels?: false,
            manage_guild?: false

  @type t() :: %__MODULE__{
          roles: [{String.t(), String.t()}],
          owner?: boolean(),
          administrator?: boolean(),
          manage_channels?: boolean(),
          manage_guild?: boolean()
        }

  alias RyushDiscord.{Connection, Guild}
  alias Guild.GuildServer

  require Logger
  use Bitwise

  @doc """
  Check the user_role_ids with the guild_roles table to get the permissions, if a role is not loaded on the guild, will update the guild_roles from the API
  """
  @spec get(Guild.t(), GuildServer.t()) :: {Guild.t(), GuildServer.t()}
  def get(%{user_role_ids: user_role_ids} = msg, %{roles: guild_roles} = state) do
    msg =
      if ids_are_updated?(user_role_ids, guild_roles) do
        %{msg | permissions: fetch_permissions(msg, state)}
      else
        new_roles =
          case Connection.get_guild_roles(msg) do
            {:ok, new_roles} ->
              Logger.debug(inspect(new_roles, pretty: true))
              new_roles

            {:error, _} ->
              Logger.debug("Cant get the role...")
              guild_roles
          end

        state = %{state | roles: new_roles}
        %{msg | permissions: fetch_permissions(msg, state)}
      end

    Logger.debug(inspect(msg.permissions, pretty: true))

    {msg, state}
  end

  defp ids_are_updated?(user_role_ids, guild_roles) do
    guild_role_ids = Enum.map(guild_roles, fn %{"id" => id} -> id end)

    Enum.all?(user_role_ids, fn x -> x in guild_role_ids end)
  end

  defp fetch_permissions(%{user_role_ids: user_role_ids, user_id: user_id}, %{
         roles: guild_roles,
         owner_id: owner_id
       }) do
    Enum.reduce(user_role_ids, __struct__(), fn user_role_id, acc ->
      guild_role = Enum.find(guild_roles, fn %{"id" => guild_id} -> guild_id == user_role_id end)
      permission = guild_role["permissions"]

      %{
        acc
        | roles: [{guild_role["id"], guild_role["name"]} | acc.roles],
          owner?: user_id == owner_id,
          administrator?: acc.administrator? || (permission &&& 0x00000008) > 0,
          manage_channels?: acc.manage_channels? || (permission &&& 0x00000010) > 0,
          manage_guild?: acc.manage_guild? || (permission &&& 0x00000020) > 0
      }
    end)
  end
end
