defmodule RyushDiscord.Guild.Flow.E621 do
  defstruct last_guild: nil, timer: 30, score_min: 50, rating: "safe", tags: []

  use GenServer, restart: :transient

  require Logger

  alias RyushE621
  alias RyushDiscord.Guild
  alias Guild.Flow

  # Used by the `RyushDiscord.Talk.DynamicSupervisor` with Guilds
  def start_link(options) do
    state = __struct__(options)
    GenServer.start_link(__MODULE__, state,
      name: Flow.get_server_name(__MODULE__, state.last_guild)
    )
  end

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    Logger.debug("Starting new Flow E621\n state: #{inspect state}")
    schedule_work(0)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    schedule_work(state.timer)

    case RyushExternal.E621.get_random_post_url(state.tags, rating: state.rating, score_min: state.score_min) do
      {:ok, url} ->
        Guild.say_text(url, state.last_guild)

      {:error, error} ->
        Logger.error("E621 error: #{error}")
    end

    {:noreply, state}
  end

  defp schedule_work(timer) do
    # in minutes
    Process.send_after(self(), :work, timer * 60 * 1000)
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating Flow E621\n Reason: #{inspect reason}\n State: #{inspect(state)} ")
  end

  #######
  # RUN #
  #######

  def run(guild, _guild_state, %{step: 0} = state) do
    if Flow.flow_exists?(__MODULE__, guild) do
      Guild.say_text("E621 disabled!", guild)
      Flow.stop_server(__MODULE__, guild)

      {:stop, :normal, state}
    else
    Guild.say_text("""
    Please set the rating
    `safe` `questionable` `explicit`
    """, guild)
    {:noreply, %{state | step: 1}}
    end

  end

  def run(%{message: message} = guild, _guild_state, %{step: 1} = state) when message in ["safe", "questionable", "explicit"] do
    Guild.say_text("""
    Now, please set the tags that you want to be send to this server, eg: 
    `paws fox female -human -comic`
    """, guild)
    {:noreply, %{state | step: 2, cache: [rating: message]}}
  end

  def run(guild, _guild_state, %{step: 1} = state) do
    Guild.say_text("""
    Please set the rating
    `safe` `questionable` `explicit`
    """, guild)
    {:noreply, state}
  end

  def run(guild, _guild_state, %{step: 2} = state) do
    tags =
      guild.message
      |> String.split()

    Guild.say_text("""
      Please set the minimum score for the posts, eg:
      `100` for a good image :smirk:
    """, guild)

    {:noreply, %{state | step: 3, cache: [tags: tags] ++ state.cache}}
  end

  def run(guild, _guild_state, %{step: 3} = state) do
    score_min =
      guild.message
      |> String.to_integer()

    Guild.say_text("""
    Plese define the time in minutes for my to keep sending the images, eg:
    `60` for 1 image each hour
    """, guild)

    {:noreply, %{state | step: 4, cache: [score_min: score_min] ++ state.cache}}
  end

  def run(guild, _guild_state, %{step: 4} = state) do
    timer =
      guild.message
      |> String.to_integer()

    Flow.start_new_server({__MODULE__, [last_guild: guild, timer: timer] ++ state.cache})

    Guild.say_text("""
    Finished :eyes:
    """, guild)

    {:stop, :normal, state}
  end
end
