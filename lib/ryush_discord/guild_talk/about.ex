defmodule RyushDiscord.GuildTalk.About do
  alias RyushDiscord.Connection

  use RyushDiscord.GuildTalk.TalkBehaviour

  paw :start, guild, guild_state, talk_state do
    Connection.say("""
      You can find my source code here:
      https://github.com/shiryel/ryush-bot

      Made with love by Shiryel, you can find he on:
      - Twitter: https://twitter.com/shiryel_
      - Art Channel: http://t.me/shiryelden
    """, guild)

    {:end, guild_state, talk_state}
  end
end
