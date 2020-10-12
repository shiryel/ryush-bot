defmodule RyushDiscord.GuildEmojer.EmojerServer do
  @moduledoc """
  """
  @type t :: [{String.t(), [String.t()]}]

  require Logger

  alias RyushDiscord.Connection

  use GenServer

  def start_link(_state) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:to_add, to_add}, _from, state) do
    {:reply, :ok, [to_add | state]}
  end

  def handle_call({:run, guild}, _from, state) do
    channel_id = guild.channel_id

    Task.start(fn ->
      Enum.each(state, fn {^channel_id, emojis} ->
        for emoji <- emojis do
          Connection.add_reaction(guild, guild.message_id, emoji)
          # Need because rate limit (like always)
          Process.sleep(500)
        end
      end)
    end)

    new_state =
      Enum.filter(state, fn
        {^channel_id, _} -> false
        _ -> true
      end)

    {:reply, :ok, new_state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug(
      "Terminating Guild Emojer\n Reason: #{inspect(reason)}\n State: #{inspect(state)} "
    )
  end
end
