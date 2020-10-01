defmodule RyushDiscord.Connection.GatewayBot.MessageWorkflow do
  @moduledoc """
  Get messages and send then to their respective `RyushDiscord.Guild`
  """
  alias RyushDiscord.{Guild}

  require Logger

  defp is_mentioning_me?(mentions) when is_list(mentions) do
    Enum.any?(mentions, fn
      %{"username" => "Ryush"} -> true
      _ -> false
    end)
  end

  defp is_myself?(user_id, state) do
    user_id == state.bot_user_id
  end

  defp get_nick_or_username(%{"member" => %{
    "nick" => nick
  }}), do: nick

  defp get_nick_or_username(%{"author" => %{
    "username" => username
  }}), do: username

  @doc """
  Process created messages
  """
  def message_create(
        %{
          "author" => %{
            "id" => user_id,
          },
          "channel_id" => channel_id,
          "content" => content,
          "guild_id" => guild_id,
          "mentions" => mentions,
        } = msg,
        state
      ) do

    %Guild{
      bot_token: state.bot_token,
      is_myself?: is_myself?(user_id, state),
      mentions_me?: is_mentioning_me?(mentions),
      message: content,
      username: get_nick_or_username(msg),
      user_id: user_id,
      channel_id: channel_id,
      guild_id: guild_id
    }
    |> Guild.process()
  end

  def message_create(msg, _state) do
    Logger.warn("[MESSAGE_CREATE] not handled: #{inspect msg}")
  end
end
