# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk.ChangePrefix do
  @moduledoc false

  alias RyushDiscord.Connection

  use RyushDiscord.GuildTalk.TalkBehaviour

  paw :start, msg, guild_state, talk_state do
    Connection.say(
      """
      **I need you to say the special keyword to me be invoked, like:**

      If you say: `!`
      Then you will call me with: `!about`

      If you say: `??`
      Then you will call me with: `??about`

      (unfortunately, spaces in the end are removed by discord :weary:)

      Im highly customizable :smile_cat:
      """,
      msg
    )

    {:change_prefix, guild_state, talk_state}
  end

  paw :change_prefix, msg, guild_state, talk_state do
    Connection.say(
      """
      Nice, now when calling me you need to do like:
      `#{msg.message}about`

      If you want another one, just run the `#{msg.message}change_prefix` or `@Ryush change_prefix` again
      ```
      """,
      msg
    )

    {:end, %{guild_state | command_prefix: msg.message}, talk_state}
  end
end
