# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk.Help do
  @moduledoc false

  alias RyushDiscord.Connection

  use RyushDiscord.GuildTalk.TalkBehaviour

  paw :start, msg, guild_state, talk_state do
    prefix = guild_state.command_prefix

    Connection.say("""
      **ADMIN**
      `#{prefix}change_prefix` change the prefix of the commands
      `#{prefix}manage_commands` manage who can use a managed command
      `#{prefix}set_notification_channel` set where the bot will send important notifications! (like what is new in a update)

      **MANAGED COMMANDS**
      `#{prefix}e621` enable/disable e621 auto image sending to the channel

      **ANYONE**
      `#{prefix}about` See bot and creator informations
      `#{prefix}help` See bot and creator informations
    """, msg)

    {:end, guild_state, talk_state}
  end
end
