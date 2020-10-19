# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk.SetNotificationChannel do
  @moduledoc false
  alias RyushDiscord.Connection

  use RyushDiscord.GuildTalk.TalkBehaviour

  paw :start, msg, guild_state, talk_state do
    Connection.say(
      """
      ```CSS
      Alright, now here is my notification channel :smile_cat:

      I'll send update infos and others important informations here!
      """,
      msg
    )

    {:end, %{guild_state | notification_channel: msg.channel_id}, talk_state}
  end
end
