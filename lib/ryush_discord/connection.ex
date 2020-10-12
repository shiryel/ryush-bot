defmodule RyushDiscord.Connection do
  @moduledoc """
  Manipulate the discord connections (websocket and HTTP)
  """

  alias RyushDiscord.Connection.ApiBot
  alias RyushDiscord.Guild

  @doc """
  Send text in the channel
  """
  @spec say(bitstring(), Guild.t()) :: :ok
  def say(text, guild) do
    body = %{
      content: text
    }

    ApiBot.create_message(guild.channel_id, body, guild.bot_token)
  end

  @spec say(nil, Guild.t(), %{atom() => any()}) :: :ok
  def say(nil, guild, embed) do
    body = %{
      embed: embed
    }

    ApiBot.create_message(guild.channel_id, body, guild.bot_token)
  end

  @spec update_say(bitstring(), Guild.t(), String.t()) :: :ok
  def update_say(text, guild, message_id) do
    body = %{
      content: text
    }

    ApiBot.update_message(guild.channel_id, message_id, body, guild.bot_token)
  end

  @spec delete_say(Guild.t, String.t()) :: :ok
  def delete_say(guild, message_id) do
    ApiBot.delete_message(guild.channel_id, message_id, guild.bot_token)
  end

  @spec get_owner_id(Guild.t) :: {:ok, binary()} | {:error, term()}
  def get_owner_id(guild) do
    ApiBot.get_owner_id(guild.guild_id, guild.bot_token)
  end

  def add_reaction(guild, message_id, emoji) do
    emoji = URI.encode(emoji)
    ApiBot.add_reaction(guild.channel_id, message_id, emoji, guild.bot_token)
  end
end
