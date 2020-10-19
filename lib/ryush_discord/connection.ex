# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.Connection do
  @moduledoc """
  Manipulate the discord connections (websocket and HTTP)
  """

  alias RyushDiscord.Connection.ApiBot
  alias RyushDiscord.Guild

  require Logger

  @doc """
  Send text in the channel
  """
  @spec say(bitstring(), Guild.t()) :: :ok
  def say(text, msg) do
    body = %{
      content: text
    }

    ApiBot.create_message(msg.channel_id, body, msg.bot_token)
  end

  @spec say(nil, Guild.t(), %{atom() => any()}) :: :ok
  def say(nil, msg, embed) do
    body = %{
      embed: embed
    }

    ApiBot.create_message(msg.channel_id, body, msg.bot_token)
  end

  @spec update_say(bitstring(), Guild.t(), String.t()) :: :ok
  def update_say(text, msg, message_id) do
    body = %{
      content: text
    }

    ApiBot.update_message(msg.channel_id, message_id, body, msg.bot_token)
  end

  @spec delete_say(Guild.t, String.t()) :: :ok
  def delete_say(msg, message_id) do
    ApiBot.delete_message(msg.channel_id, message_id, msg.bot_token)
  end

  def add_reaction(msg, message_id, emoji) do
    emoji = URI.encode(emoji)
    ApiBot.add_reaction(msg.channel_id, message_id, emoji, msg.bot_token)
  end

  @spec get_owner_id(Guild.t) :: {:ok, binary()} | {:error, term()}
  def get_owner_id(msg) do
    ApiBot.get_owner_id(msg.guild_id, msg.bot_token)
  end

  def get_guild_roles(msg) do
    ApiBot.get_guild_roles(msg.guild_id, msg.bot_token)
  end
end
