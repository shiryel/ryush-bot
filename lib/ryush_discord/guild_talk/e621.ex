defmodule RyushDiscord.GuildTalk.E621 do
  @moduledoc """
  Talk to send messages automaticaly periodically using the `RyushDiscord.Flow.E621`
  """

  alias RyushDiscord.{GuildFlow, GuildTalk, Connection}
  alias GuildFlow.{E621}

  use GuildTalk.TalkBehaviour

  require Logger

  paw :start, guild, guild_state, talk_state do
    if E621.exists?(guild) do
      Connection.say("E621 disabled!", guild)
      E621.stop(guild)

      {:end, guild_state, talk_state}
    else
      Connection.say(
        """
        Please set the rating
        `safe` `questionable` `explicit`
        """,
        guild
      )

      {:rating, guild_state, talk_state}
    end
  end

  paw :rating, %{message: message} = guild, guild_state, talk_state,
    when: message in ["safe", "questionable", "explicit"] do
    Connection.say(
      """
      Now, please set the tags that you want to be send to this server, eg: 
      `paws fox female -human -comic`

      Note: extreme tags needs `login` and a `api_key` of your account, that feature is not implemented yet on this bot
      """,
      guild
    )

    {:tags, guild_state, %{talk_state | cache: [rating: message]}}
  end

  paw :rating, guild, guild_state, talk_state do
    Connection.say(
      """
      Please set the rating
      `safe` `questionable` `explicit`
      """,
      guild
    )

    {:rating, guild_state, talk_state}
  end

  paw :tags, guild, guild_state, talk_state do
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

    {:min_score, guild_state, %{talk_state | cache: [tags: tags] ++ talk_state.cache}}
  end

  paw :min_score, guild, guild_state, talk_state do
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

    {:time, guild_state, %{talk_state | cache: [score_min: score_min] ++ talk_state.cache}}
  end

  paw :time, guild, guild_state, talk_state do
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

    {:sauce, guild_state, %{talk_state | step: 5, cache: [timer: timer] ++ talk_state.cache}}
  end

  paw :sauce, %{message: message} = guild, guild_state, talk_state, when: message in ["yes", "no"] do
    show_sauce? =
      case message do
        "yes" ->
          true

        "no" ->
          false
      end

    E621.start([last_guild: guild, show_sauce?: show_sauce?] ++ talk_state.cache)

    Connection.say(
      """
      Finished :eyes:
      """,
      guild
    )

    {:end, guild_state, talk_state}
  end

  paw :sauce, guild, guild_state, talk_state do
    Connection.say(
      """
      Do you want the sauce?
      `yes` `no`
      """,
      guild
    )

    {:sauce, guild_state, talk_state}
  end
end
