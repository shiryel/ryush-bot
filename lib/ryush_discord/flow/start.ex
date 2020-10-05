defmodule RyushDiscord.Flow.Start do
  @moduledoc """
  Start workflow, gets the handler
  """
  alias RyushDiscord.Connection

  def run(guild, guild_state, %{step: 0} = state) do
    Connection.say(
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

    {:reply, guild_state, %{state | step: 1}}
  end

  def run(%{message: message} = guild, guild_state, %{step: 1} = state) do
    Connection.say(
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

    {:stop, :normal, %{guild_state | message_handler: message}, state}
  end
end
