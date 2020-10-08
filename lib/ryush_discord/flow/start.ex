defmodule RyushDiscord.Flow.Start do
  @moduledoc """
  Start workflow, gets the handler
  """
  alias RyushDiscord.Connection
  use RyushDiscord.Talk.TalkBehaviour

  paw :start, guild, guild_state, talk_state do
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

    {:end, guild_state, talk_state}
  end

  paw :end, guild, guild_state, talk_state do
    Connection.say(
      """
      Nice, now when calling me you need to do like:
      `#{guild.message}about`

      If you want another one, just run the `@Ryush start` again

      ```CSS
      [Admin Channel]

      And the last config that you need to do is to define my private control channel, be aware THAT ANYBODY WHO IS ON THIS CHANNEL CAN SEND ADMIN COMANDS TO ME! with:
      ```
      `#{guild.message}admin_channel_here`
      """,
      guild
    )

    {:stop, %{guild_state | message_handler: guild.message}, talk_state}
  end
end
