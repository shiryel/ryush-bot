# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk.Start do
  @moduledoc """
  Start workflow, gets the handler
  """
  alias RyushDiscord.Connection

  use RyushDiscord.GuildTalk.TalkBehaviour

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

    {:start_end, guild_state, talk_state}
  end

  paw :start_end, guild, guild_state, talk_state do
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

    {:end, %{guild_state | command_prefix: guild.message}, talk_state}
  end
end
