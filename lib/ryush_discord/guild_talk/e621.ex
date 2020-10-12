defmodule RyushDiscord.GuildTalk.E621 do
  @moduledoc """
  Talk to send messages automaticaly periodically using the `RyushDiscord.Flow.E621`
  """

  alias RyushDiscord.{GuildEmojer, GuildFlow, GuildTalk, Connection}
  alias GuildFlow.{E621}

  use GuildTalk.TalkBehaviour

  require Logger

  defp show_menu(guild, talk_state) do
    Connection.say(
      """
      **Click on the emoji and type the value!** (will update this message)

      ------------------------------------------
      🇷 : `rating` => #{talk_state.cache.rating}

      👀 : `tags` => #{talk_state.cache.tags}

      💖 : `score min` => #{talk_state.cache.score_min}

      🕐 : `time` => #{talk_state.cache.timer}

      🧐 : `show sauce?` => #{
        cond do
          # For some reason dialyzer is crazy and I cant use if else -w-
          talk_state.cache.show_sauce? -> "yes"
          true -> "no"
        end
      }
      ------------------------------------------

      ▶️  : `start` => starts the bot

      ------------------------------------------
      """,
      guild
    )
  end

  defp update_menu(guild, talk_state) do
    Connection.update_say(
      """
      **Click on the emoji and type the value!** (will update this message)

      ------------------------------------------
      🇷 : `rating` => #{talk_state.cache.rating}

      👀 : `tags` => #{talk_state.cache.tags}

      💖 : `score min` => #{talk_state.cache.score_min}

      🕐 : `time` => #{talk_state.cache.timer}

      🧐 : `show sauce?` => #{if talk_state.cache.show_sauce?, do: "yes", else: "no"}
      ------------------------------------------

      ▶️  : `start` => starts the bot

      ------------------------------------------
      """,
      guild,
      talk_state.last_emoji_message_id
    )
  end

  defp delete_responses(guild, talk_state) do
    last_emoji_message_id = talk_state.last_emoji_message_id

    Task.start(fn ->
      Enum.each(talk_state.message_ids, fn
        x when x != last_emoji_message_id ->
          Connection.delete_say(guild, x)
          Process.sleep(500)

        _ ->
          :ok
      end)
    end)
  end

  paw :start, guild, guild_state, talk_state do
    if E621.exists?(guild) do
      Connection.say("E621 disabled!", guild)
      E621.stop(guild)

      {:end, guild_state, talk_state}
    else
      cache = %E621{
        rating: "safe",
        tags: "paws fox -human -comic",
        score_min: 150,
        show_sauce?: true,
        timer: 60
      }

      talk_state = %{talk_state | cache: cache}

      GuildEmojer.to_add(guild.channel_id, ~w[🇷 👀 💖 🕐 🧐 ▶️])
      show_menu(guild, talk_state)

      {:menu_run, guild_state, talk_state}
    end
  end

  paw :menu_run, %{emoji: %{name: "🇷"}} = guild, guild_state, talk_state do
    Connection.say(
      """
      Please set the rating
      `safe` `questionable` `explicit`
      """,
      guild
    )

    {:rating, guild_state, talk_state}
  end

  paw :rating, %{message: message} = guild, guild_state, talk_state,
    when: message in ["safe", "questionable", "explicit"] do
    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | rating: message})
    update_menu(guild, talk_state)
    delete_responses(guild, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "👀"}} = guild, guild_state, talk_state do
    Connection.say(
      """
      Please set the tags that you want to be send to this server, eg: 
      `paws fox female -human -comic`

      Note: extreme tags needs `login` and a `api_key` of your account, that feature is not implemented yet on this bot
      """,
      guild
    )

    {:tags, guild_state, talk_state}
  end

  paw :tags, guild, guild_state, talk_state do
    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | tags: guild.message})
    update_menu(guild, talk_state)
    delete_responses(guild, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "💖"}} = guild, guild_state, talk_state do
    Connection.say(
      """
      Please set the minimum score for the posts, eg:
      `150` for a good image :smirk:
      """,
      guild
    )

    {:min_score, guild_state, talk_state}
  end

  paw :min_score, guild, guild_state, talk_state do
    score_min =
      guild.message
      |> String.to_integer()

    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | score_min: score_min})
    update_menu(guild, talk_state)
    delete_responses(guild, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "🕐"}} = guild, guild_state, talk_state do
    Connection.say(
      """
      Plese define the time in minutes for my to keep sending the images, eg:
      `60` for 1 image each hour
      """,
      guild
    )

    {:timer, guild_state, talk_state}
  end

  paw :timer, guild, guild_state, talk_state do
    timer =
      case guild.message
           |> String.to_integer() do
        x when x < 1 ->
          1

        x ->
          x
      end

    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | timer: timer})
    update_menu(guild, talk_state)
    delete_responses(guild, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "🧐"}} = guild, guild_state, talk_state do
    Connection.say(
      """
      Do you want the sauce?
      `yes` `no`
      """,
      guild
    )

    {:sauce, guild_state, talk_state}
  end

  paw :sauce, %{message: message} = guild, guild_state, talk_state, when: message in ["yes", "no"] do
    show_sauce? =
      case message do
        "yes" ->
          true

        "no" ->
          false
      end

    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | show_sauce?: show_sauce?})
    update_menu(guild, talk_state)
    delete_responses(guild, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "▶️"}} = guild, guild_state, talk_state do
    cache = %{talk_state.cache | last_guild: guild}
    E621.start(cache)

    {:end, guild_state, talk_state}
  end

  paw _, _guild, guild_state, talk_state do
    {:menu_run, guild_state, talk_state}
  end
end
