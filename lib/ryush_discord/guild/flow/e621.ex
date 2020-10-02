defmodule RyushDiscord.Guild.Flow.E621 do
  @enforce_keys ~w|last_guild tags|a
  defstruct last_guild: nil, timer: 30, tags: []

  use GenServer, restart: :transient

  require Logger

  alias RyushE621
  alias RyushDiscord.Guild
  alias Guild.Flow

  # Used by the `RyushDiscord.Talk.DynamicSupervisor` with Guilds
  def start_link(guild: guild, tags: tags) do
    GenServer.start_link(__MODULE__, %__MODULE__{last_guild: guild, tags: tags},
      name: Flow.get_server_name(__MODULE__, guild)
    )
  end

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    Logger.debug("Starting new Flow E621\n state: #{inspect state}")
    {:ok, state}
  end

  @impl true
  def handle_cast(:start, state) do
    schedule_work(state.timer)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_timer, minutes}, state) do
    {:noreply, %{state | timer: minutes}}
  end

  @impl true
  def handle_info(:work, state) do
    schedule_work(state.timer)

    case RyushExternal.E621.get_random_post_url(state.tags) do
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
    Guild.say_text("""
    Please set the tags that you want to be send to this server, eg: 
    `paws fox female`
    """, guild)

    {:noreply, %{state | step: 1}}
  end

  def run(guild, _guild_state, %{step: 1} = state) do
    tags =
      guild.message
      |> String.split()

    Flow.start_new_server({__MODULE__, guild: guild, tags: tags})

    Guild.say_text("""
    Plese define the time in minutes for my to keep sending the images, eg:
    `60` for 1 image each hour
    """, guild)

    {:noreply, %{state | step: 2}}
  end

  def run(guild, _guild_state, %{step: 2} = state) do
    timer =
      guild.message
      |> String.to_integer()

    Flow.send_cast(__MODULE__, guild, {:set_timer, timer})
    Flow.send_cast(__MODULE__, guild, :start)

    Guild.say_text("""
    Finished :smile_cat:
    """, guild)

    {:stop, :normal, state}
  end
end
