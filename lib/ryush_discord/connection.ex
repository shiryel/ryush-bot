defmodule RyushDiscord.Connection do
  @moduledoc """
  Manipulate the discord connections (websocket and HTTP)
  """

  alias RyushDiscord.Connection.ApiBot
  alias RyushDiscord.Guild

  @doc """
  Send text in the channel
  """
  @spec say(binary(), Guild.t()) :: :ok
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

  @spec get_owner_id(Guild.t) :: {:ok, binary()} | {:error, term()}
  def get_owner_id(guild) do
    ApiBot.get_owner_id(guild)
  end
end
