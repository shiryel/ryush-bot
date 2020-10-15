# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushDiscord.Connection.GatewayBot.HandshakeWorkflow do
  @moduledoc """
  Handshake workflow used by GatewayBot

  Discord docs: https://discord.com/developers/docs/topics/gateway#connecting-to-the-gateway

  ### Workflow:
  - start_link -> receive Hello -> schedule Heartbeat -> send Identify
  - (if identify is invalid or exceed the limit) receive Invalid Session -> send Identify after 1..5 secs
  - (if identify is valid) receive Ready -> put info into `state`
  - on connection/reconnection try to resume if `session_id` exists on `state`
  """
  @behaviour RyushDiscord.Connection.GatewayBot

  require Logger

  ##########################
  ####### CONNECTING #######

  ############
  # Resuming #
  ############
  @impl true
  def connect_workflow(
        _conn,
        %{
          session_started?: true,
          session_id: session_id,
          bot_token: bot_token,
          s: seq
        } = state
      ) do
    Logger.notice("Resuming connection...")

    command =
      %{
        op: 6,
        d: %{
          token: bot_token,
          session_id: session_id,
          seq: seq
        }
      }
      |> Jason.encode!()

    WebSockex.send_frame(GatewayBot, {:text, command})
    {:ok, state}
  end

  ###################
  # Normal Workflow #
  ###################
  def connect_workflow(_conn, state) do
    Logger.notice("Starting new connection...")

    schedule_identify(1000)
    schedule_heartbeat(state.heartbeat_interval)
    {:ok, state}
  end

  #########################
  ####### RECEIVING #######

  ############
  # Reconnec #
  ############
  def frame_workflow(
        %{
          "op" => 7
        } = _message,
        state
      ) do
    Logger.notice("Attempting to reconnect... (request from server)")

    # Need to reconnect, but WebSockex dont suport it...
    {:close, {4009, "Session timed out"}, state}
  end

  ###################
  # Invalid Session #
  ###################
  def frame_workflow(
        %{
          "op" => 9
        } = message,
        state
      ) do
    Logger.error(
      "Invalid session, please check the token or try again! message: #{inspect(message)}"
    )

    schedule_identify(Enum.random(1000..5000))
    {:ok, state}
  end

  #########
  # Hello #
  #########
  @impl true
  def frame_workflow(
        %{
          "d" => %{
            "heartbeat_interval" => heartbeat_interval
          },
          "op" => 10
        },
        state
      ) do
    Logger.info("Received Hello")

    {:ok, %{state | heartbeat_interval: heartbeat_interval}}
  end

  #################
  # Heartbeat ACK #
  #################
  def frame_workflow(
        %{
          "op" => 11
        },
        state
      ) do
    if state.heartbeat_sent_without_response > 3 do
      # restart connection because maybe its a zombied or failed connection

      # Need to reconnect, but WebSockex dont suport it...
      {:close, {4009, "Session timed out"}, state}
    else
      {:ok, %{state | heartbeat_sent_without_response: 0}}
    end
  end

  #########
  # Ready #
  #########
  def frame_workflow(
        %{
          "d" => %{
            "application" => _appliscation,
            "guilds" => _guilds,
            "presences" => _presences,
            # where the messages will be received by the bot
            "private_channels" => _private_channels,
            "relationships" => _relationships,
            "session_id" => session_id,
            "user" => _user,
            "user_settings" => _user_settings,
            "v" => _version
          },
          "op" => 0,
          "t" => "READY"
        },
        state
      ) do
    Logger.info("Received Ready")

    {:ok, %{state | session_id: session_id, session_started?: true}}
  end

  def frame_workflow(message, state) do
    Logger.error("Frame workflow not handled for message: #{inspect(message)}")
    {:ok, state}
  end

  #######################
  ####### SENDING #######

  defp schedule_heartbeat(heartbeat_interval) do
    Process.send_after(self(), :send_heartbeat, heartbeat_interval)
  end

  defp schedule_identify(interval) do
    Process.send_after(self(), :send_identify, interval)
  end

  #############
  # Heartbeat #
  #############
  @impl true
  def info_workflow(:send_heartbeat, state) do
    schedule_heartbeat(state.heartbeat_interval)

    command = %{op: 1, d: state.s} |> Jason.encode!()

    {:reply, {:text, command},
     %{state | heartbeat_sent_without_response: state.heartbeat_sent_without_response + 1}}
  end

  ############
  # Identify #
  ############
  def info_workflow(:send_identify, state) do
    Logger.info("Sending identify")

    command =
      %{
        op: 2,
        d: %{
          token: state.bot_token,
          properties: %{
            "$os" => "linux",
            "$browser" => "ryush",
            "$device" => "ryush"
          }
        }
      }
      |> Jason.encode!()

    {:reply, {:text, command}, state}
  end

  def info_workflow(message, state) do
    Logger.error("Info workflow not handled for message: #{inspect(message, pretty: true)}")
    {:ok, state}
  end
end
