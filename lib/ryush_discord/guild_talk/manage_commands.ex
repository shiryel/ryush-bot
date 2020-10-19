# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.GuildTalk.ManageCommands do
  @moduledoc false
  alias RyushDiscord.Connection

  use RyushDiscord.GuildTalk.TalkBehaviour
  alias RyushDiscord.{GuildEmojer}

  defp show_roles_of_command(command, guild_state) do
    ids = guild_state.command_roles[command]

    names =
      Enum.map(ids, fn id ->
        Enum.find(guild_state.roles, fn role -> role["id"] == id end)
        |> Map.get("name")
      end)

    for x <- names do
      "`#{x}`  "
    end
  end

  defp show_menu(msg, guild_state) do
    Connection.say(
      """
      **Click on the emoji to change the roles!** (will update this message)

      ------------------------------------------
      🇷 : `e621` => #{show_roles_of_command(:e621, guild_state)}

      ------------------------------------------

      ▶️ : FINISH CONFIGURATION

      """,
      msg
    )
  end

  defp update_menu(msg, guild_state, talk_state) do
    Connection.update_say(
      """
      **Click on the emoji to change the roles!** (will update this message)

      ------------------------------------------
      🇷 : `e621` => #{show_roles_of_command(:e621, guild_state)}

      ------------------------------------------

      ▶️ : FINISH CONFIGURATION

      """,
      msg,
      talk_state.last_emoji_message_id
    )
  end

  defp show_roles(msg, guild_state) do
    Connection.say(
      """
      **Please select all the ROLES IDS** that can call the command, separated by spaces

      **Here's all the roles and they IDs:**
      #{
        for x <- guild_state.roles do
          "`#{x["name"]}` - `#{x["id"]}`\n"
        end
      }
      Example:
      `758135580030271509 758138210743615529 758791822473691207`
      For seting 3 roles to manage the command
      """,
      msg
    )
  end

  defp delete_responses(msg, talk_state) do
    last_emoji_message_id = talk_state.last_emoji_message_id

    Task.start(fn ->
      Enum.each(talk_state.message_ids, fn
        x when x != last_emoji_message_id ->
          Connection.delete_say(msg, x)
          Process.sleep(500)

        _ ->
          :ok
      end)
    end)
  end

  paw :start, msg, guild_state, talk_state do
    GuildEmojer.to_add(msg.channel_id, ~w[🇷 ▶️])
    show_menu(msg, guild_state)

    {:menu_run, guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "🇷"}} = msg, guild_state, talk_state do
    show_roles(msg, guild_state)

    {:e621, guild_state, talk_state}
  end

  paw :e621, %{message: message} = msg, guild_state, talk_state do
    ids = String.split(message)
    new_guild_state = %{guild_state | command_roles: %{guild_state.command_roles | e621: ids}}

    update_menu(msg, new_guild_state, talk_state)
    delete_responses(msg, talk_state)
    {:menu_run, new_guild_state, talk_state}
  end

  paw :menu_run, %{emoji: %{name: "▶️"}} = msg, guild_state, talk_state do
    Connection.say("FINISHED!", msg)
    {:end, guild_state, talk_state}
  end

  paw _, _guild, guild_state, talk_state do
    {:menu_run, guild_state, talk_state}
  end
end
