defmodule RyushDiscord.Flow.E621 do
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

  use GenServer, restart: :transient

  require Logger

  alias RyushE621
  alias RyushDiscord.{Flow, Connection}
  alias Flow.{FlowRegistry, FlowSupervisor}

  # Used by the `RyushDiscord.Talk.DynamicSupervisor` with Guilds
  def start_link(options) do
    state = __struct__(options)
    GenServer.start_link(__MODULE__, state, name: get_server_name(state.last_guild))
  end

  def stop_server(guild) do
    GenServer.stop(get_server_name(guild), :normal)
  end

  defp get_server_name(guild) do
    {:via, Registry, {FlowRegistry, {__MODULE__, guild.channel_id}}}
  end

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

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    Logger.debug("Starting new Flow E621\n state: #{inspect(state)}")
    schedule_work(0)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, %{e621_cache: [hd | tail]} = state) do
    schedule_work(state.timer)
    send_e621(hd, state)

    {:noreply, %{state | e621_cache: tail}}
  end

  def handle_info(:work, state) do
    schedule_work(state.timer)

    case RyushExternal.E621.get_random_post_urls(state.tags,
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

  defp schedule_work(timer) do
    # in minutes
    Process.send_after(self(), :work, timer * 60 * 1000)
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating Flow E621\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end

  #######
  # RUN #
  #######

  def run(guild, guild_state, %{step: 0} = state) do
    if FlowRegistry.exists?(__MODULE__, guild) do
      Connection.say("E621 disabled!", guild)
      stop_server(guild)

      {:stop, :normal, guild_state, state}
    else
      Connection.say(
        """
        Please set the rating
        `safe` `questionable` `explicit`
        """,
        guild
      )

      {:reply, guild_state, %{state | step: 1}}
    end
  end

  def run(%{message: message} = guild, guild_state, %{step: 1} = state)
      when message in ["safe", "questionable", "explicit"] do
    Connection.say(
      """
      Now, please set the tags that you want to be send to this server, eg: 
      `paws fox female -human -comic`

      Note: extreme tags needs `login` and a `api_key` of your account, that feature is not implemented yet on this bot
      """,
      guild
    )

    {:reply, guild_state, %{state | step: 2, cache: [rating: message]}}
  end

  def run(guild, guild_state, %{step: 1} = state) do
    Connection.say(
      """
      Please set the rating
      `safe` `questionable` `explicit`
      """,
      guild
    )

    {:reply, guild_state, state}
  end

  def run(guild, guild_state, %{step: 2} = state) do
    tags =
      guild.message
      |> String.split()

    Connection.say(
      """
        Please set the minimum score for the posts, eg:
        `100` for a good image :smirk:
      """,
      guild
    )

    {:reply, guild_state, %{state | step: 3, cache: [tags: tags] ++ state.cache}}
  end

  def run(guild, guild_state, %{step: 3} = state) do
    score_min =
      guild.message
      |> String.to_integer()

    Connection.say(
      """
      Plese define the time in minutes for my to keep sending the images, eg:
      `60` for 1 image each hour
      """,
      guild
    )

    {:reply, guild_state, %{state | step: 4, cache: [score_min: score_min] ++ state.cache}}
  end

  def run(guild, guild_state, %{step: 4} = state) do
    timer =
      case guild.message
           |> String.to_integer() do
        x when x < 1 ->
          1

        x ->
          x
      end

    Connection.say(
      """
      Do you want the sauce?
      `yes` `no`
      """,
      guild
    )

    {:reply, guild_state, %{state | step: 5, cache: [timer: timer] ++ state.cache}}
  end

  def run(%{message: message} = guild, guild_state, %{step: 5} = state)
      when message in ["yes", "no"] do
    show_sauce? =
      case message do
        "yes" ->
          true

        "no" ->
          false
      end

    FlowSupervisor.start_new(
      {__MODULE__, [last_guild: guild, show_sauce?: show_sauce?] ++ state.cache}
    )

    Connection.say(
      """
      Finished :eyes:
      """,
      guild
    )

    {:stop, :normal, guild_state, state}
  end

  def run(guild, guild_state, %{step: 5} = state) do
    Connection.say(
      """
      Do you want the sauce?
      `yes` `no`
      """,
      guild
    )

    {:reply, guild_state, state}
  end
end
