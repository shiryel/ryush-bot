# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk.About do
  @moduledoc false

  alias RyushDiscord.Connection

  use RyushDiscord.GuildTalk.TalkBehaviour

  paw :start, msg, guild_state, talk_state do
    Connection.say("""
      You can find my source code here:
      https://github.com/shiryel/ryush-bot

      Made with love by Shiryel, you can find he on:
      - Twitter: https://twitter.com/shiryel_
      - Art Channel: http://t.me/shiryelden
    """, msg)

    {:end, guild_state, talk_state}
  end
end
