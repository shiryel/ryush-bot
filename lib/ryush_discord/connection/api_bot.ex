defmodule RyushDiscord.Connection.ApiBot do
  @moduledoc """
  APIs for controlling the bot

  Discord docs: https://discord.com/developers/docs/topics/gateway#get-gateway-bot
  """
  require Logger

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://discord.com/api/v7"
  plug Tesla.Middleware.JSON

  @type gateway_bot :: %{
          session_start_limit: %{
            max_concurrency: integer(),
            remaining: integer(),
            reset_after: integer(),
            total: integer()
          },
          shards: integer(),
          url: String.t()
        }

  @type error_reason ::
          :unauthorized | {:rate_limit, integer()} | :other

  @doc """
  Get the URL for connecting with the bot websocket
  """
  @spec gateway_bot(String.t()) :: {:ok, gateway_bot()} | {:error, error_reason()}
  def gateway_bot(bot_token) do
    case get("/gateway/bot", headers: [{"authorization", "Bot #{bot_token}"}]) do
      ###################
      # Normal workflow #
      ###################
      {:ok,
       %Tesla.Env{
         body: %{
           "session_start_limit" => %{
             "max_concurrency" => max_concurrency,
             "remaining" => remaining,
             "reset_after" => reset_after,
             "total" => total
           },
           "shards" => shards,
           "url" => url
         },
         status: 200
       }} ->
        {:ok,
         %{
           session_start_limit: %{
             max_concurrency: max_concurrency,
             remaining: remaining,
             reset_after: reset_after,
             total: total
           },
           shards: shards,
           url: url
         }}

      ################
      # Unauthorized #
      ################
      {:ok,
       %Tesla.Env{
         status: 401
       }} ->
        {:error, :unauthorized}

      ##############
      # Rate Limit #
      ##############
      {:ok,
       %Tesla.Env{
         body: %{"retry_after" => retry_after},
         status: 429
       }} ->
        {:error, {:rate_limit, retry_after}}

      dump ->
        Logger.error(inspect(dump))
        {:error, :other}
    end
  end

  @doc """
  Create a message on a channel
  """
  @spec create_message(binary(), any, binary()) :: :ok
  def create_message(channel_id, body, bot_token) do
    case Jason.encode(body) do
      {:ok, body} ->
        post("/channels/#{channel_id}/messages", body,
          headers: [{"authorization", "Bot #{bot_token}"}, {"content-type", "application/json"}]
        )
        |> inspect()
        |> Logger.debug()

      {:error, _} ->
        Logger.error("Invalid body #{inspect(body)}")
    end
    :ok
  end
end
