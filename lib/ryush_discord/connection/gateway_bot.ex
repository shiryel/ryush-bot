defmodule RyushDiscord.Connection.GatewayBot do
  @moduledoc """
  Websocket bot connection

  Some notes:
  - This is only 1 process, remember to spawn another process to dont block the main thread!
  """

  defstruct bot_token: "",
            session_started?: false,
            session_id: "",
            heartbeat_sent_without_response: 0,
            heartbeat_interval: 4250,
            s: nil

  use WebSockex

  alias __MODULE__.{HandshakeWorkflow, MessageWorkflow}

  require Logger

  @gateway_params "/?v=6&encoding=json"

  def start_link(bot_token: bot_token) do
    case RyushDiscord.Connection.ApiBot.gateway_bot(bot_token) do
      {:ok, %{url: url}} ->
        state = %__MODULE__{bot_token: bot_token}
        WebSockex.start_link(url <> @gateway_params, __MODULE__, state)

      {:error, {:rate_limit, rate_limit}} ->
        Logger.warn("Rate Limited!!!")
        :timer.sleep(rate_limit)
        {:error, :rate_limit}

      {:error, :unauthorized} ->
        Logger.error("Token unauthorized!")
        {:error, :unauthorized}

      {:error, error} ->
        {:error, error}
    end
  end

  #############
  # CALLBACKS #
  #############

  @doc """
  The handle_connect/2 workflow
  """
  @callback connect_workflow(conn :: WebSockex.Conn.t(), state :: term) ::
              {:ok, new_state :: term}

  @doc """
  The handle_frame/2 workflow
  """
  @callback frame_workflow(match :: term(), state :: term()) ::
              {:ok, new_state}
              | {:reply, frame, new_state}
              | {:close, new_state}
              | {:close, close_frame, new_state}
            when new_state: term, close_frame: WebSockex.close_frame(), frame: WebSockex.frame()

  @doc """
  The handle_info/2 workflow
  """
  @callback info_workflow(msg :: term, state :: term) ::
              {:ok, new_state}
              | {:reply, frame, new_state}
              | {:close, new_state}
              | {:close, close_frame, new_state}
            when new_state: term, close_frame: WebSockex.close_frame(), frame: WebSockex.frame()

  ############
  # WORKFLOW #
  ############

  @impl true
  def handle_connect(conn, state) do
    HandshakeWorkflow.connect_workflow(conn, state)
  end

  @impl true
  def handle_frame({:text, message}, state) do
    # Get SEQ
    {msg, state} =
      case Jason.decode(message) do
        {:ok, %{"op" => 0, "s" => s} = msg} ->
          {msg, %{state | s: s}}

        {:ok, msg} ->
          {msg, state}

        {:error, error} ->
          Logger.error(inspect(error))
          {:ignore, state}
      end

    # Handle server message
    case msg do
      :ignore ->
        {:ok, state}

      %{"op" => 0, "t" => "READY"} = msg ->
        # Handshake workflow
        HandshakeWorkflow.frame_workflow(msg, state)

      %{"op" => 0} = msg ->
        # This operations will not change state, so...
        Task.start(fn -> async_workflow(msg, state) end)
        {:ok, state}

      msg ->
        # Handshake workflow
        HandshakeWorkflow.frame_workflow(msg, state)
    end
  end

  def handle_frame({type, msg}, state) do
    Logger.warn(~s|Type "#{inspect(type)}" or msg "#{inspect(msg)}" not handled|)
    {:ok, state}
  end

  @impl true
  def handle_info(message, state) do
    HandshakeWorkflow.info_workflow(message, state)
  end

  @impl true
  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end

  @impl true
  def terminate(close_reason, _state) do
    Logger.error("Terminating websocket, reason: #{inspect(close_reason)}")
    :ok
  end

  defp async_workflow(%{"d" => msg, "t" => type}, state) do
    case type do
      "MESSAGE_CREATE" ->
        MessageWorkflow.message_create(msg, state)

      other ->
        IO.inspect(other)
    end
  end
end
