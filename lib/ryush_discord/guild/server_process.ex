defmodule RyushDiscord.Guild.ServerProcess do
  @moduledoc """
  The default process implementation of the `RyushDiscord.Guild.GuildServer`
  """

  require Logger
  alias RyushDiscord.{GuildTalk, Connection}

  use RyushDiscord.Guild.GuildBehaviour

  ###############
  # PRE-PROCESS #
  ###############

  # Get owner id
  paw :system, :pre_process, guild, %{owner_id: nil} = state do
    case Connection.get_owner_id(guild) do
      {:ok, owner_id} ->
        {:system, :pre_process, guild, %{state | owner_id: owner_id}}

      {:error, error} ->
        Logger.error("Cant get the get owner id, error: #{inspect(error)}")
        {:end, state}
    end
  end

  # Ignore myself
  paw :system, :pre_process, %{is_myself?: true}, state do
    {:end, state}
  end

  # Needs command_prefix from owner
  paw :system, :pre_process, guild, %{command_prefix: nil} = state do
    if guild.user_id == state.owner_id do
      {:owner, :command_prefix, guild, state}
    else
      {:end, state}
    end
  end

  # Is a mention
  paw :system, :pre_process, %{mentions_me?: true} = guild, state do
    if guild.user_id == state.owner_id do
      {:owner, :mention, guild, state}
    else
      {:anyone, :mention, guild, state}
    end
  end

  # Remove the command_prefix (if exists) or try to continue talk
  paw :system, :pre_process, guild, state do
    if String.match?(guild.message, ~r/^#{state.command_prefix}[[:alnum:]]+/) do
      guild = %{
        guild
        | message: String.replace(guild.message, state.command_prefix, "", global: false)
      }

      if guild.user_id == state.owner_id do
        {:owner, :run, guild, state}
      else
        if guild.channel_id == state.admin_channel do
          {:admin, :run, guild, state}
        else
          {:anyone, :run, guild, state}
        end
      end
    else
      Logger.debug("Guild: trying to continue talk")
      GuildTalk.process(guild, state, :continue_talk)
      {:end, state}
    end
  end

  #################
  # OWNER PROCESS #
  #################

  # Owner mention handler
  # - start (and SET MESSAGE HANDLER)
  # - [anything]
  paw :owner, :command_prefix, %{mentions_me?: true} = guild, state do
    if String.contains?(guild.message, "start") do
      Logger.debug("Guild: start mention found, starting talk :start")
      GuildTalk.process(guild, state, :start)
    else
      Logger.debug("Guild: any mention found")

      Connection.say(
        """
        ```CSS
        *BEEP BOOP*
        ```
        Hello #{guild.username}, My name is Ryush and I need your assistence...
        Lets say that... well...

        Just mention me again with the start command, like this:
        `@Ryush start`
        """,
        guild
      )
    end

    {:end, state}
  end

  # MESSAGE HANDLER NEEDED
  paw :owner, :command_prefix, guild, state do
    case GuildTalk.process(guild, state, :continue_talk) do
      {:error, :talk_not_found} ->
        Logger.debug("Guild: :continue_talk not found and message handler needed")

        Connection.say(
          """
          ```CSS
          *BEEP BOOP*
          ```
          Hello #{guild.username}, My name is Ryush and I need your assistence...
          Lets say that... well...

          Just mention me again with the start command, like this:
          `@Ryush start`
          """,
          guild
        )

        {:end, state}

      {:ok, state} ->
        Process.send_after(self(), {:update_db, guild.guild_id}, 5000)
        {:end, state}
    end
  end

  paw :owner, :mention, guild, state do
    cond do
      String.contains?(guild.message, "start") ->
        GuildTalk.process(guild, state, :start)

      String.contains?(guild.message, "about") ->
        GuildTalk.process(guild, state, :about)

      String.contains?(guild.message, "help") ->
        GuildTalk.process(guild, state, :help)

      true ->
        :ok
    end

    {:end, state}
  end

  # SET ADMIN CHANNEL HERE
  paw :owner, :run, %{message: "admin_channel_here"} = guild, state do
    Connection.say(
      """
      ```CSS
      [Admin Channel seted]
      ANYBODY WHO IS ON THIS CHANNEL CAN SEND ADMIN COMANDS TO ME!
      ```
      """,
      guild
    )

    Process.send_after(self(), {:update_db, guild.guild_id}, 5000)

    {:end, %{state | admin_channel: guild.channel_id}}
  end

  # ADMIN CHANNEL NEEDED
  paw :owner, :run, guild, %{admin_channel: nil} = state do
    Connection.say(
      """
      Please, use the `#{state.command_prefix}admin_channel_here` to define a admin channel for the bot!
      """,
      guild
    )

    {:end, state}
  end

  # |> admin_process/2
  paw :owner, :run, guild, state do
    {:admin, :run, guild, state}
  end

  #################
  # ADMIN COMANDS #
  #################
  paw :admin, :run, %{message: "e621"} = guild, state do
    case GuildTalk.process(guild, state, :e621) do
      {:ok, state} ->
        {:end, state}

      {:error, _} ->
        {:end, state}
    end
  end

  paw :admin, :run, guild, state do
    {:anyone, :run, guild, state}
  end

  ###################
  # NORMAL COMMANDS #
  ###################

  paw :anyone, :mention, %{message: message} = guild, state do
    cond do
      String.contains?(message, "about") ->
        GuildTalk.process(guild, state, :about)

      String.contains?(message, "help") ->
        GuildTalk.process(guild, state, :help)

      true ->
        :ok
    end

    {:end, state}
  end

  paw :anyone, :run, %{message: "about"} = guild, state do
    GuildTalk.process(guild, state, :about)
    {:end, state}
  end

  paw :anyone, :run, %{message: "help"} = guild, state do
    GuildTalk.process(guild, state, :help)
    {:end, state}
  end

  # Default handler
  paw :anyone, :run, guild, state do
    Logger.debug("Not handled: guild |#{inspect(guild)}| state |#{inspect(state)}|")
    {:end, state}
  end
end
