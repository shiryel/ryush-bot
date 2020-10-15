# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildFlow.E621 do
  @moduledoc """
  Connects your channel to the E621 API, getting a image each `:timer` minutes
  """

  defstruct last_guild: nil,
            timer: 30,
            score_min: 50,
            rating: "safe",
            tags: [],
            show_sauce?: false,
            e621_cache: []

  alias RyushDiscord.{Guild, Connection}
  alias RyushE621
  alias :mnesia, as: Mnesia

  @type t :: %__MODULE__{
          last_guild: Guild.t(),
          timer: integer(),
          score_min: integer,
          rating: String.t(),
          tags: [String.t()],
          show_sauce?: boolean(),
          e621_cache: [term()]
        }

  use RyushDiscord.GuildFlow.FlowBehaviour

  require Logger

  defp random_color do
    Enum.random(String.to_integer("eb9494", 16)..String.to_integer("a094eb", 16))
  end

  defp send_e621(e621, state) do
    if state.show_sauce? do
      # webm dont show on embeded mode
      if String.match?(e621.url, ~r/.+webm/) do
        Connection.say(
          """
          sauce: #{e621.id} 
          #{e621.url}
          """,
          state.last_guild
        )
      else
        Connection.say(nil, state.last_guild, %{
          title: e621.id,
          url: "https://e621.net/posts/#{e621.id}",
          image: %{url: e621.url},
          color: random_color()
        })
      end
    else
      Connection.say("#{e621.url}", state.last_guild)
    end
  end

  defp schedule_work(timer) do
    # in minutes
    Process.send_after(self(), :work, timer * 60 * 1000)
  end

  def schedule_update_db(channel_id, timer_mm) do
    Process.send_after(self(), {:update_db, channel_id}, timer_mm)
  end

  #############
  # BEHAVIOUR #
  #############

  @impl true
  def start_link(struct: struct) do
    GenServer.start_link(__MODULE__, struct, name: get_server_name(struct.last_guild))
  end

  @impl true
  def on_restart do
    Mnesia.wait_for_tables([__MODULE__], 2000)

    # defaults the attributes to [key, val]
    Mnesia.create_table(__MODULE__, [])

    {:atomic, keys} = 
      fn -> Mnesia.all_keys(__MODULE__) end |> :mnesia.transaction()

    for key <- keys do
      case fn -> Mnesia.read(__MODULE__, key) end |> Mnesia.transaction() do
        {:atomic, [{_, _, state}]} ->
          Logger.debug("Database found! updating...")

          start(state)

        _ ->
          Logger.warn("Database not found")
      end
    end
    :ok
  end

  @impl true
  def init(state) do
    Logger.debug("Starting new Flow E621\n state: #{inspect(state)}")
    schedule_work(0)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, %{e621_cache: [hd | tail]} = state) do
    schedule_work(state.timer)
    schedule_update_db(state.last_guild.channel_id, 5000)
    send_e621(hd, state)

    {:noreply, %{state | e621_cache: tail}}
  end

  def handle_info(:work, state) do
    schedule_work(state.timer)
    schedule_update_db(state.last_guild.channel_id, 5000)

    tags =
      state.tags
      |> String.split()

    case RyushExternal.E621.get_random_post_urls(tags,
           rating: state.rating,
           score_min: state.score_min
         ) do
      {:ok, []} ->
        Connection.say(
          "Error: Maybe a tag dont exists or is black-listed (needing your account)",
          state.last_guild
        )

        {:noreply, state}

      {:ok, [hd | tail]} ->
        if length(tail) < 15 do
          Connection.say("Warning: The tags are too restrictive!", state.last_guild)
        end

        send_e621(hd, state)
        {:noreply, %{state | e621_cache: tail}}

      {:error, error} ->
        Logger.error("E621 error: #{error}")
        {:noreply, state}
    end
  end

  def handle_info({:update_db, channel_id}, state) do
    fn ->
      Mnesia.write({__MODULE__, channel_id, state})
    end
    |> Mnesia.transaction()

    Mnesia.dump_tables([__MODULE__])

    Logger.debug("Database #{__MODULE__} updated!")

    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating Flow E621\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end
end
