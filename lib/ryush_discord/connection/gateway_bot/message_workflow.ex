defmodule RyushDiscord.Connection.GatewayBot.MessageWorkflow do
  @moduledoc """
  Get messages and send then to their respective guild_id server
  """
  alias RyushDiscord.Connection.ApiBot
  require Logger

  def message_create(
        %{
          "attachments" => [],
          "author" => %{
            "avatar" => _avatar,
            "discriminator" => _discriminator,
            "id" => _author_id,
            "public_flags" => _public_flags,
            "username" => username
          },
          "channel_id" => channel_id,
          "content" => _content,
          "edited_timestamp" => _edited_timestamp,
          "embeds" => _embeds,
          "flags" => _flags,
          "guild_id" => _guilds_id,
          "id" => _id,
          "member" => %{
            "deaf" => _deaf,
            "hoisted_role" => _hoisted_role,
            "joined_at" => _joined_at,
            "mute" => _mute,
            "roles" => _roles
          },
          "mention_everyone" => _mention_everyone?,
          "mention_roles" => _mention_rules,
          "mentions" => _mentions,
          "nonce" => _nonce,
          "pinned" => _pinned?,
          "referenced_message" => _referenced_message,
          "timestamp" => _timestamp,
          "tts" => _tts?,
          "type" => _type
        },
        state
      ) do
    content =
      %{
        content: "Hello, #{username}"
      }
      |> Jason.encode!()

    ApiBot.create_message(channel_id, content, state.bot_token)
    |> IO.inspect()

    Process.sleep(20000)
    {:ok, state}
  end

  def message_create(msg, _state) do
    Logger.warn("[MESSAGE_CREATE] not handled: #{inspect msg}")
  end
end
