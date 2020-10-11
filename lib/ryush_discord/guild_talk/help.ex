defmodule RyushDiscord.GuildTalk.Help do
  alias RyushDiscord.Connection

  use RyushDiscord.GuildTalk.TalkBehaviour

  paw :start, guild, guild_state, talk_state do
    prefix = guild_state.command_prefix

    Connection.say("""
      **ADMIN**
      `#{prefix}e621` enable/disable e621 auto image sending to the channel

      **ANYONE**
      `#{prefix}about` See bot and creator informations
      `#{prefix}help` See bot and creator informations
    """, guild)

    {:end, guild_state, talk_state}
  end
end
