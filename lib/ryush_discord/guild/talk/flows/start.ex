defmodule RyushDiscord.Guild.Talk.Flows.Start do
  alias RyushDiscord.Guild

  def run(guild, _guild_state, %{step: 0} = state) do
    Guild.say_text(
      """
      ```CSS
      [Keyword Configuration]

      First I need you to say the special keyword to me be invoked, like:
      ```
      If you say: `!`
      Then you will call me with: `!about`

      If you say: `??`
      Then you will call me with: `??about`

      (unfortunately, spaces in the end are removed by discord :weary:)

      Im highly customizable :smile_cat:
      """,
      guild
    )

    {:noreply, %{state | step: 1}}
  end

  def run(%{message: message} = guild, guild_state, %{step: 1} = state) do
    Guild.say_text(
      """
      Nice, now when calling me you need to do like:
      `#{message}about`

      If you want another one, just run the `@Ryush start` again

      ```CSS
      [Admin Channel]

      And the last config that you need to do is to define my private control channel, be aware THAT ANYBODY WHO IS ON THIS CHANNEL CAN SEND ADMIN COMANDS TO ME! with:
      ```
      `#{message}admin_channel_here`
      """,
      guild
    )

    Guild.update_guild_state(guild, %{guild_state | message_handler: message})
    {:noreply, %{state | step: 2}}
  end

  # Dont receive the message_handler on the message
  def run(%{message: "admin_channel_here"} = guild, guild_state, %{step: 2} = state) do
    Guild.say_text(
      """
      ```CSS
      [Configuration Complete]
      ```
      Now you can start to play with me, see my commands with:
      `#{guild_state.message_handler}help`

      And more about me and my creator with:
      `#{guild_state.message_handler}about`
      """,
      guild
    )

    Guild.update_guild_state(guild, guild_state)
    {:stop, :normal, state}
  end

  def run(guild, %{message_handler: message_handler}, %{step: 2} = state) do
    Guild.say_text(
      """
      Please, use the `#{message_handler}admin_channel_here` to define a admin channel for the bot!
      """,
      guild
    )

    {:noreply, %{state | step: 2}}
  end
end
