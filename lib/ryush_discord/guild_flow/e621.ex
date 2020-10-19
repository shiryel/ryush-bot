# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program.

defmodule RyushDiscord.GuildFlow.E621 do
  @moduledoc """
  Connects your channel to the E621 API, getting a image each `:timer` minutes
  """

  defstruct last_msg: nil,
            timer: 30,
            score_min: 50,
            ratings: ["safe"],
            tags: [],
            show_sauce?: false,
            e621_cache: []

  alias RyushDiscord.{Guild, Connection}
  alias RyushE621
  alias :mnesia, as: Mnesia

  @type t :: %__MODULE__{
          last_msg: Guild.t(),
          timer: integer(),
          score_min: integer,
          ratings: [String.t()],
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
          state.last_msg
        )
      else
        Connection.say(nil, state.last_msg, %{
          title: e621.id,
          url: "https://e621.net/posts/#{e621.id}",
          image: %{url: e621.url},
          color: random_color()
        })
      end
    else
      Connection.say("#{e621.url}", state.last_msg)
    end
  end

  defp schedule_work(timer) do
    # in minutes
    Process.send_after(self(), :work, timer * 60 * 1000)
  end

  def schedule_update_db(timer_mm) do
    Process.send_after(self(), :update_db, timer_mm)
  end

  #############
  # BEHAVIOUR #
  #############

  @impl true
  # Used to only show the warning when its a new link from the USER! not the DB!
  # Just ot dont explode the e621 API :P
  def start_link(struct: struct, new: true) do
    tags =
      struct.tags
      |> String.split()

    size =
      case RyushExternal.E621.get_quantity(tags,
             ratings: struct.ratings,
             score_min: struct.score_min
           ) do
        {:ok, size} ->
          size

        _ ->
          # ignore error
          320
      end

    if size < 300 do
      Connection.say(
        """
        **Warning: The tags are too restrictive!**
        Maybe repeated images will show in the future! 

        Only #{size} images found!
        """,
        struct.last_msg
      )
    end

    GenServer.start_link(__MODULE__, struct, name: get_server_name(struct.last_msg))
  end

  def start_link(struct: struct, new: false) do
    GenServer.start_link(__MODULE__, struct, name: get_server_name(struct.last_msg))
  end

  @impl true
  def on_restart do
    Mnesia.wait_for_tables([__MODULE__], 2000)

    # defaults the attributes to [key, val]
    Mnesia.create_table(__MODULE__, [disc_only_copies: [node()]])

    {:atomic, keys} = fn -> Mnesia.all_keys(__MODULE__) end |> :mnesia.transaction()

    for key <- keys do
      case fn -> Mnesia.read(__MODULE__, key) end |> Mnesia.transaction() do
        {:atomic, [{_, _, state}]} ->
          Logger.debug("Database found! updating...")

          start_from_db(state)

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
    schedule_update_db(5000)
    send_e621(hd, state)

    {:noreply, %{state | e621_cache: tail}}
  end

  def handle_info(:work, state) do
    schedule_work(state.timer)
    schedule_update_db(5000)

    tags =
      state.tags
      |> String.split()

    posts =
      RyushExternal.E621.get_random_post_urls(tags,
        ratings: state.ratings,
        score_min: state.score_min
      )

    case posts do
      {:ok, []} ->
        Connection.say(
          "Error: Maybe a tag dont exists or is black-listed (needing your account)",
          state.last_msg
        )

        {:noreply, state}

      {:ok, [hd | tail]} ->
        send_e621(hd, state)
        {:noreply, %{state | e621_cache: tail}}

      {:error, error} ->
        Logger.error("E621 error: #{error}")
        {:noreply, state}
    end
  end

  def handle_info(:update_db, state) do
    fn ->
      Mnesia.write({__MODULE__, state.last_msg.channel_id, state})
    end
    |> Mnesia.transaction()

    Mnesia.dump_tables([__MODULE__])

    Logger.debug("Database #{__MODULE__} updated!")

    {:noreply, state}
  end

  @impl true
  def terminate(:normal, state) do
    Logger.debug("Terminating normaly Flow E621")

    fn ->
      Mnesia.delete_object({__MODULE__, state.last_msg.channel_id})
    end
    |> Mnesia.transaction()

    Logger.debug("Database #{__MODULE__} deleted!")

    {:stop, :normal, :ok, state}
  end

  def terminate(reason, state) do
    Logger.warn("Terminating Flow E621\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end
end
