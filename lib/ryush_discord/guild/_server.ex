defmodule RyushDiscord.Guild.GuildServer do
  @moduledoc """
  The guild main controller, will foward some talks to `RyushDiscord.Guild.Talk.TalkServer`

  handle_cast -> pre_process |--> process_mention()
                             |--> owner_process()
                             |--> process()
                              
  """
  defstruct message_handler: nil,
            admin_channel: nil,
            owner_id: nil

  @type t :: %__MODULE__{message_handler: binary(), admin_channel: binary(), owner_id: binary()}

  alias RyushDiscord.{Guild, Talk, Connection}
  alias Guild.{GuildRegistry}

  require Logger

  use GenServer, restart: :transient

  def start_link(guild: guild) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: get_server_name(guild))
  end

  @doc """
  Get the server name

  Used to create and find the guild servers through the `RyushDiscord.Guild.GuildRegistry`
  """
  def get_server_name(guild) do
    {:via, Registry, {GuildRegistry, guild.guild_id}}
  end

  #############
  # GENSERVER #
  #############

  @impl true
  def init(state) do
    Logger.debug("Starting new guild\n state: #{inspect(state)}")
    {:ok, state}
  end

  @impl true
  def handle_cast({:process, guild}, state) do
    pre_process(guild, state)
  end

  def handle_cast(request, state) do
    Logger.error("cant handle: request |#{inspect(request)}| state |#{inspect(state)}|")

    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating Guild\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end

  ###############
  # PRE-PROCESS #
  ###############

  # Get external info
  defp pre_process(guild, %{owner_id: nil} = state) do
    case Connection.get_owner_id(guild) do
      {:ok, owner_id} ->
        Logger.debug("Guild get owner_id")
        pre_process(guild, %{state | owner_id: owner_id})

      {:error, error} ->
        Logger.error("Cant get the owner ID #{inspect(error)}")
        {:noreply, state}
    end
  end

  # Ignore myself
  defp pre_process(%{is_myself?: true}, state), do: {:noreply, state}

  # MESSAGE_HANDLER NEEDED (only owner can handle)
  defp pre_process(guild, %{message_handler: nil} = state) do
    if guild.user_id == state.owner_id do
      Logger.debug("Guild: message_handler not found... routing to owner_process/2")
      owner_process(guild, state)
    else
      {:noreply, state}
    end
  end

  # Remove the message_handler (if exists)
  # |> owner_process/2
  # |> process/2
  #
  # Or Try to :continue_talk
  defp pre_process(guild, state) do
    if String.match?(guild.message, ~r/^#{state.message_handler}[[:alnum:]]+/) do
      guild = %{
        guild
        | message: String.replace(guild.message, state.message_handler, "", global: false)
      }

      if guild.user_id == state.owner_id do
        Logger.debug("Guild: routing to owner_process/2")
        owner_process(guild, state)
      else
        Logger.debug("Guild: routing to choose_process/2")
        choose_process(guild, state)
      end
    else
      Logger.debug("Guild: trying to continue talk")
      Talk.process(guild, state, :continue_talk)
      {:noreply, state}
    end
  end

  #################
  # OWNER PROCESS #
  #################

  # Owner mention handler
  # - start (and SET MESSAGE HANDLER)
  # - [anything]
  defp owner_process(%{mentions_me?: true, message: message} = guild, state) do
    if String.contains?(message, "start") do
      Logger.debug("Guild: start mention found, starting talk :start")
      Talk.process(guild, state, :start)
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

    {:noreply, state}
  end

  # MESSAGE HANDLER NEEDED
  defp owner_process(guild, %{message_handler: nil} = state) do
    case Talk.process(guild, state, :continue_talk) do
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

        {:noreply, state}

      {:ok, state} ->
        {:noreply, state}
    end
  end

  # SET ADMIN CHANNEL HERE
  defp owner_process(%{message: "admin_channel_here"} = guild, state) do
    Logger.debug("Guild: set admin_channel_here")

    Connection.say(
      """
      ```CSS
      [Admin Channel seted]
      ANYBODY WHO IS ON THIS CHANNEL CAN SEND ADMIN COMANDS TO ME!
      ```
      """,
      guild
    )

    {:noreply, %{state | admin_channel: guild.channel_id}}
  end

  # ADMIN CHANNEL NEEDED
  defp owner_process(guild, %{admin_channel: nil} = state) do
    Logger.debug("Guild: admin_channel not found")

    Connection.say(
      """
      Please, use the `#{state.message_handler}admin_channel_here` to define a admin channel for the bot!
      """,
      guild
    )

    {:noreply, state}
  end

  # |> admin_process/2
  defp owner_process(guild, state) do
    Logger.debug("Guild: routing from owner_process/2 to admin_process/2")
    admin_process(guild, state)
  end

  ###########
  # PROCESS #
  ###########

  # Choose the rule
  # |> admin_process/2
  # |> normal_process/2
  defp choose_process(guild, state) do
    if guild.channel_id == state.admin_channel do
      Logger.debug("Guild: routing from choose_process/2 to admin_process/2")
      admin_process(guild, state)
    else
      Logger.debug("Guild: routing from choose_process/2 to normal_process/2")
      normal_process(guild, state)
    end
  end

  #################
  # ADMIN COMANDS #
  #################
  defp admin_process(%{message: "e621"} = guild, state) do
    Logger.debug("Guild: starting Talk :e621")

    case Talk.process(guild, state, :e621) do
      {:ok, state} ->
        {:noreply, state}

      {:error, _} ->
        {:noreply, state}
    end
  end

  defp admin_process(guild, state) do
    Logger.debug("Guild: routing from admin_process/2 to normal_process/2")
    normal_process(guild, state)
  end

  ###################
  # NORMAL COMMANDS #
  ###################
  # Default handler
  defp normal_process(guild, state) do
    Logger.warn("Not handled: guild |#{inspect(guild)}| state |#{inspect(state)}|")
    {:noreply, state}
  end
end
