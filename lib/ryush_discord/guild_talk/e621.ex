# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk.E621 do
  @moduledoc false

  alias RyushDiscord.{GuildEmojer, GuildFlow, GuildTalk, Connection}
  alias GuildFlow.{E621}

  use GuildTalk.TalkBehaviour

  require Logger

  defp show_menu(msg, talk_state) do
    Connection.say(
      """
      **Click on the emoji and type the value!** (will update this message)

      ------------------------------------------
      🇷 : `rating` => #{Enum.reduce(talk_state.cache.ratings, "", &("#{&1} " <> &2))}

      👀 : `tags` => #{talk_state.cache.tags}

      💖 : `score min` => #{talk_state.cache.score_min}

      🕐 : `time` => #{talk_state.cache.timer}

      🧐 : `show sauce?` => #{
        cond do
          # For some reason dialyzer is crazy and I cant use if else -w-
          talk_state.cache.show_sauce? -> "yes"
          not talk_state.cache.show_sauce? -> "no"
          true -> "no"
        end
      }
      ------------------------------------------

      ▶️  : `start` => starts the bot

      ------------------------------------------
      """,
      msg
    )
  end

  defp update_menu(msg, talk_state) do
    Connection.update_say(
      """
      **Click on the emoji and type the value!** (will update this message)

      ------------------------------------------
      🇷 : `rating` => #{Enum.reduce(talk_state.cache.ratings, "", &("#{&1} " <> &2))}

      👀 : `tags` => #{talk_state.cache.tags}

      💖 : `score min` => #{talk_state.cache.score_min}

      🕐 : `time` => #{talk_state.cache.timer}

      🧐 : `show sauce?` => #{if talk_state.cache.show_sauce?, do: "yes", else: "no"}
      ------------------------------------------

      ▶️  : `start` => starts the bot

      ------------------------------------------
      """,
      msg,
      talk_state.last_emoji_message_id
    )
  end

  defp delete_responses(msg, talk_state) do
    last_emoji_message_id = talk_state.last_emoji_message_id

    Task.start(fn ->
      Enum.each(talk_state.message_ids, fn
        x when x != last_emoji_message_id ->
          Connection.delete_say(msg, x)
          Process.sleep(500)

        _ ->
          :ok
      end)
    end)
  end

  paw :start, msg, guild_state, talk_state do
    if E621.exists?(msg) do
      Logger.debug("e621 alread exists, exiting!")
      Connection.say("E621 disabled!", msg)
      E621.stop(msg)

      {:end, guild_state, talk_state}
    else
      Logger.debug("e621 dont exists, creating a new one!")

      cache = %E621{
        ratings: ["safe"],
        tags: "paws -human -comic",
        score_min: 100,
        show_sauce?: true,
        timer: 60
      }

      talk_state = %{talk_state | cache: cache}

      GuildEmojer.to_add(msg.channel_id, ~w[🇷 👀 💖 🕐 🧐 ▶️])
      show_menu(msg, talk_state)

      {:menu_run, guild_state, talk_state}
    end
  end

  paw :menu_run, %{emoji: %{name: "🇷"}} = msg, guild_state, talk_state do
    Connection.say(
      """
      Please set the ratings
      `safe` `questionable` `explicit`

      you can set multiple ratings, eg:
      `safe questionable`
      For puting the bot to work with both!
      """,
      msg
    )

    {:ratings, guild_state, talk_state}
  end

  paw :ratings, %{message: message} = msg, guild_state, talk_state do
    ratings = String.split(message)

    any_wrong? = Enum.any?(ratings, &(&1 not in ["safe", "questionable", "explicit"]))

    if any_wrong? do
      Connection.say("Invalid ratings, try again!", msg)

      {:ratings, guild_state, talk_state}
    else
      talk_state = Map.put(talk_state, :cache, %{talk_state.cache | ratings: ratings})
      update_menu(msg, talk_state)
      delete_responses(msg, talk_state)

      {:menu_run, guild_state, talk_state}
    end
  end

  paw :menu_run, %{emoji: %{name: "👀"}} = msg, guild_state, talk_state do
    Connection.say(
      """
      Please set the tags that you want to be send to this server, eg: 
      `paws fox female -human -comic`

      Note: extreme tags needs `login` and a `api_key` of your account, that feature is not implemented yet on this bot
      """,
      msg
    )

    {:tags, guild_state, talk_state}
  end

  paw :tags, msg, guild_state, talk_state do
    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | tags: msg.message})
    update_menu(msg, talk_state)
    delete_responses(msg, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "💖"}} = msg, guild_state, talk_state do
    Connection.say(
      """
      Please set the minimum score for the posts, eg:
      `150` for a good image :smirk:
      """,
      msg
    )

    {:min_score, guild_state, talk_state}
  end

  paw :min_score, msg, guild_state, talk_state do
    score_min =
      msg.message
      |> String.to_integer()

    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | score_min: score_min})
    update_menu(msg, talk_state)
    delete_responses(msg, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "🕐"}} = msg, guild_state, talk_state do
    Connection.say(
      """
      Plese define the time in minutes for my to keep sending the images, eg:
      `60` for 1 image each hour
      """,
      msg
    )

    {:timer, guild_state, talk_state}
  end

  paw :timer, msg, guild_state, talk_state do
    timer =
      case msg.message
           |> String.to_integer() do
        x when x < 1 ->
          1

        x ->
          x
      end

    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | timer: timer})
    update_menu(msg, talk_state)
    delete_responses(msg, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "🧐"}} = msg, guild_state, talk_state do
    Connection.say(
      """
      Do you want the sauce?
      `yes` `no`
      """,
      msg
    )

    {:sauce, guild_state, talk_state}
  end

  paw :sauce, %{message: message} = msg, guild_state, talk_state, when: message in ["yes", "no"] do
    show_sauce? =
      case message do
        "yes" ->
          true

        "no" ->
          false
      end

    talk_state = Map.put(talk_state, :cache, %{talk_state.cache | show_sauce?: show_sauce?})
    update_menu(msg, talk_state)
    delete_responses(msg, talk_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "▶️"}} = msg, guild_state, talk_state do
    cache = %{talk_state.cache | last_msg: msg}
    E621.start(cache)

    {:end, guild_state, talk_state}
  end

  paw _, _msg, guild_state, talk_state do
    {:menu_run, guild_state, talk_state}
  end
end
