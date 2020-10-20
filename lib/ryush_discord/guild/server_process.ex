# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.Guild.ServerProcess do
  @moduledoc """
  Defines the `c:RyushDiscord.Guild.GuildBehaviour.paw_run/4` used by `RyushDiscord.Guild.GuildServer`
  """

  require Logger
  alias RyushDiscord.{GuildEmojer, GuildTalk, Connection}
  alias RyushDiscord.Guild.Permissions

  use RyushDiscord.Guild.GuildBehaviour

  ###############
  # PRE-PROCESS #
  ###############

  paw :system, :start, msg, %{owner_id: nil} = state do
    case Connection.get_owner_id(msg) do
      {:ok, owner_id} ->
        {:system, :start, msg, %{state | owner_id: owner_id}}

      {:error, error} ->
        Logger.error("Cant get the get owner id, error: #{inspect(error)}")
        {:end, state}
    end
  end

  paw :system, :start, msg, state do
    {msg, state} = Permissions.get(msg, state)
    {:system, :pre_process, msg, state}
  end

  # Myself
  paw :system, :pre_process, msg, state, when: msg.is_myself? do
    Logger.debug("Its myself...")
    GuildEmojer.run(msg)

    case GuildTalk.process(msg, state, :continue_talk) do
      {:ok, state} ->
        {:end, state}

      _ ->
        {:end, state}
    end

    {:end, state}
  end

  # Is a mention
  paw :system, :pre_process, msg, state, when: msg.mentions_me? do
    Logger.debug("It mentions me...")
    {:admin, :mention, msg, state}
  end

  # When is not a message just continue the talk...
  paw :system, :pre_process, msg, state, when: is_nil(msg.message) do
    Logger.debug("Its not a message...")

    case GuildTalk.process(msg, state, :continue_talk) do
      {:ok, state} ->
        {:end, state}

      _ ->
        {:end, state}
    end
  end

  # Remove the command_prefix (if exists) or try to continue talk
  paw :system, :pre_process, msg, state do
    Logger.debug("Try to remove prefix and choose branch...")

    match? = String.match?(msg.message, ~r/^#{Regex.escape(state.command_prefix)}[[:alnum:]]+/)

    if match? do
      msg = %{
        msg
        | message: String.replace(msg.message, state.command_prefix, "", global: false)
      }

      if msg.permissions.owner? or msg.permissions.administrator? do
        Logger.debug("Redirect to admin branch...")
        {:admin, :run, msg, state}
      else
        Logger.debug("Redirect to anyone branch...")
        {:anyone, :run, msg, state}
      end
    else
      Logger.debug("No prefix found, trying to continue talk")

      case GuildTalk.process(msg, state, :continue_talk) do
        {:ok, new_state} ->
          {:end, new_state}

        {:error, _} ->
          {:end, state}
      end
    end
  end

  #################
  # ADMIN COMANDS #
  #################

  @admin_talks_with_update ~w[change_prefix manage_commands set_notification_channel]

  paw :admin, :run, msg, state, when: msg.message in @admin_talks_with_update do
    Logger.debug("[admin] #{msg.message} command found")

    case GuildTalk.process(msg, state, String.to_atom(msg.message)) do
      {:ok, new_state} ->
        Process.send_after(self(), {:update_db, msg.guild_id}, 5000)
        {:end, new_state}

      {:error, _} ->
        {:end, state}
    end
  end

  paw :admin, :mention, msg, state do
    get_talk =
      Enum.find(@admin_talks_with_update, false, fn x -> String.contains?(msg.message, x) end)

    if get_talk in @admin_talks_with_update do
      case GuildTalk.process(msg, state, String.to_atom(get_talk)) do
        {:ok, new_state} ->
          Process.send_after(self(), {:update_db, msg.guild_id}, 5000)
          {:end, new_state}

        {:error, _} ->
          {:end, state}
      end
    else
      {:managed, :run, msg, state}
    end
  end

  paw :admin, :run, msg, state do
    Logger.debug("No admin command found, redirect to managed commands")
    {:managed, :run, msg, state}
  end

  ####################
  # MANAGED COMMANDS #
  ####################

  @managed_talks ~w[e621]

  paw :managed, :run, msg, state, when: msg.message in @managed_talks do
    command = String.to_atom(msg.message)

    has_permission? =
      Enum.any?(msg.permissions.roles, fn {id, _name} ->
        id in state.command_roles[command]
      end) || msg.permissions.administrator? || msg.permissions.owner?

    if has_permission? do
      case GuildTalk.process(msg, state, command) do
        {:ok, new_state} ->
          {:end, new_state}

        {:error, _} ->
          {:end, state}
      end
    else
      {:anyone, :run, msg, state}
    end
  end

  paw :managed, :run, msg, state do
    Logger.debug("No managed command found, redirect to anyone commands")
    {:anyone, :run, msg, state}
  end

  ###################
  # NORMAL COMMANDS #
  ###################

  @anyone_talks ~w[about help]

  paw :anyone, :run, msg, state, when: msg.message in @anyone_talks do
    Logger.debug("#{msg.message} command found")

    case GuildTalk.process(msg, state, String.to_atom(msg.message)) do
      {:ok, new_state} ->
        {:end, new_state}

      {:error, _} ->
        {:end, state}
    end
  end

  paw :anyone, :mention, msg, state do
    get_talk = Enum.find(@anyone_talks, false, fn x -> String.contains?(msg.message, x) end)

    if get_talk in @anyone_talks do
      case GuildTalk.process(msg, state, String.to_atom(get_talk)) do
        {:ok, new_state} ->
          {:end, new_state}

        {:error, _} ->
          {:end, state}
      end
    else
      {:anyone, :run, msg, state}
    end
  end

  # Default handler
  paw :anyone, :run, msg, state do
    Logger.debug("Not handled: msg |#{inspect(msg)}| state |#{inspect(state)}|")
    {:end, state}
  end
end
