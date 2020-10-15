# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildEmojer do
  @moduledoc """
  Async add emojis on a channel_id message
  """
  alias __MODULE__.EmojerServer
  alias RyushDiscord.Guild

  require Logger

  @doc """
  Add a new list of emojis to be added on the next message of the channel_id
  """
  @spec to_add(String.t(), [String.t()]) :: :ok
  def to_add(channel_id, emojis) do
    GenServer.call(EmojerServer, {:to_add, {channel_id, emojis}})
  catch
    :exit, _ ->
      Logger.warn("Emojer server timeout")
      :ok
  end

  @doc """
  Run the Emojer on a given guild
  """
  @spec run(Guild.t()) :: :ok
  def run(guild) do
    GenServer.call(EmojerServer, {:run, guild})
  catch
    :exit, _ ->
      Logger.warn("Emojer server timeout")
      :ok
  end
end
