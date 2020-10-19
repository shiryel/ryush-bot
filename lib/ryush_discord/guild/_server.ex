# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.Guild.GuildServer do
  @moduledoc """
  The guild main controller, will foward some talks to `RyushDiscord.Guild.Talk.TalkServer`

  Uses the default behaviour `RyushDiscord.Guild.ServerProcess`
  """
  defstruct command_prefix: "!",
            notification_channel: nil,
            last_message_user_id: nil,
            owner_id: nil,
            roles: [],
            command_roles: %{e621: []}

  @type t :: %__MODULE__{
          command_prefix: String.t(),
          notification_channel: String.t(),
          last_message_user_id: String.t(),
          owner_id: String.t(),
          roles: [any],
          command_roles: [{atom(), [String.t()]}]
        }

  alias RyushDiscord.Guild
  alias Guild.{GuildRegistry, ServerProcess}
  alias :mnesia, as: Mnesia

  require Logger

  use GenServer, restart: :transient

  def start_link(msg: msg) do
    Mnesia.wait_for_tables([__MODULE__], 2000)
    # defaults the attributes to [key, val]
    Mnesia.create_table(__MODULE__, disc_only_copies: [node()])

    state =
      case fn -> Mnesia.read(__MODULE__, msg.guild_id) end |> Mnesia.transaction() do
        {:atomic,
         [
           {_, _,
            %{
              command_prefix: command_prefix,
              command_roles: command_roles,
              notification_channel: notification_channel,
              roles: roles
            }}
         ]} ->
          Logger.debug("Database found! updating...")

          %__MODULE__{}
          |> Map.put(:command_prefix, command_prefix)
          |> Map.put(:notification_channel, notification_channel)
          |> Map.put(:command_roles, command_roles)
          |> Map.put(:roles, roles)

        # This would work like a countinuous migration?
        # Update DB on 5 seconds to 5 hours
        # This is the migration time
        # Process.send_after(self(), {:update_db, msg.guild_id}, Enum.random(5..(5 * 60 * 60)) * 1000)

        _ ->
          Logger.debug("Database not found")
          %__MODULE__{}
      end

    GenServer.start_link(__MODULE__, state, name: get_server_name(msg))
  end

  @doc """
  Get the server name

  Used to create and find the guild servers through the `RyushDiscord.Guild.GuildRegistry`
  """
  def get_server_name(msg) do
    {:via, Registry, {GuildRegistry, msg.guild_id}}
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
  def handle_cast({:process, msg}, state) do
    ServerProcess.paw_run(:system, :start, msg, state)
  end

  def handle_cast(request, state) do
    Logger.error("cant handle: request |#{inspect(request)}| state |#{inspect(state)}|")

    {:noreply, state}
  end

  @impl true
  def handle_info({:update_db, guild_id}, state) do
    fn ->
      Mnesia.write({__MODULE__, guild_id, state})
    end
    |> Mnesia.transaction()

    Logger.debug("Database #{__MODULE__} updated!")

    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.debug("Terminating Guild\n Reason: #{inspect(reason)}\n State: #{inspect(state)} ")
  end
end
