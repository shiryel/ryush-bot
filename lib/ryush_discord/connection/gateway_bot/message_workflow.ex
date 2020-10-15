defmodule RyushDiscord.Connection.GatewayBot.MessageWorkflow do
  @moduledoc """
  Get messages and send then to their respective `RyushDiscord.Guild`
  """
  alias RyushDiscord.{Guild}

  require Logger

  defp is_mentioning_me?(mentions, state) when is_list(mentions) do
    bot_user_id = state.bot_user_id

    Enum.any?(mentions, fn
      %{"id" => ^bot_user_id} -> true
      _ -> false
    end)
  end

  defp is_myself?(user_id, state) do
    user_id == state.bot_user_id
  end

  defp get_nick_or_username(%{
         "member" => %{
           "nick" => nick
         }
       }),
       do: nick

  defp get_nick_or_username(%{
         "author" => %{
           "username" => username
         }
       }),
       do: username

  defp get_nick_or_username(%{"member" => %{"user" => %{"username" => username}}}),
    do: username

  @doc """
  Process created messages
  """
  def message_create(
        %{
          "author" => %{
            "id" => user_id
          },
          "id" => message_id,
          "channel_id" => channel_id,
          "content" => content,
          "guild_id" => guild_id,
          "mentions" => mentions
        } = msg,
        state
      ) do

    inspect(msg, pretty: true)
    |> Logger.debug()

    %Guild{
      bot_token: state.bot_token,
      is_myself?: is_myself?(user_id, state),
      mentions_me?: is_mentioning_me?(mentions, state),
      message: content,
      message_id: message_id,
      username: get_nick_or_username(msg),
      user_id: user_id,
      channel_id: channel_id,
      guild_id: guild_id
    }
    |> Guild.process()
  end

  def message_reaction_add(
        %{
          "channel_id" => channel_id,
          "emoji" => %{"id" => emoji_id, "name" => emoji_name},
          "guild_id" => guild_id,
          "message_id" => message_id,
          "user_id" => user_id
        } = msg,
        state
      ) do
    %Guild{
      bot_token: state.bot_token,
      is_myself?: is_myself?(user_id, state),
      mentions_me?: false,
      message: nil,
      emoji: %{id: emoji_id, name: emoji_name},
      message_id: message_id,
      username: get_nick_or_username(msg),
      user_id: user_id,
      channel_id: channel_id,
      guild_id: guild_id
    }
    |> Guild.process()
  end

  def message_create(msg, _state) do
    Logger.warn("[MESSAGE_CREATE] not handled: #{inspect(msg)}")
  end
end
