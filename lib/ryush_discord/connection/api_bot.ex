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

      # |> inspect()
      # |> Logger.debug()

      {:error, _} ->
        Logger.error("Invalid body #{inspect(body)}")
    end

    :ok
  end

  def update_message(channel_id, message_id, body, bot_token) do
    case(
      patch("/channels/#{channel_id}/messages/#{message_id}", body,
        headers: [{"authorization", "Bot #{bot_token}"}, {"content-type", "application/json"}]
      )
    ) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.warn(error)
    end

    :ok
  end

  def delete_message(channel_id, message_id, bot_token) do
    case delete("/channels/#{channel_id}/messages/#{message_id}", headers: [{"authorization", "Bot #{bot_token}"}, {"content-type", "application/json"}]) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.warn(error)
    end
  end

  def get_owner_id(guild_id, bot_token) do
    case get("/guilds/#{guild_id}",
           headers: [
             {"authorization", "Bot #{bot_token}"},
             {"content-type", "application/json"}
           ]
         ) do
      {:ok,
       %Tesla.Env{
         __client__: %Tesla.Client{adapter: nil, fun: nil, post: [], pre: []},
         __module__: RyushDiscord.Connection.ApiBot,
         body: %{
           "owner_id" => owner_id
         }
       }} ->
        {:ok, owner_id}

      {:error, error} ->
        {:error, error}
    end
  end

  def add_reaction(channel_id, message_id, emoji, bot_token) do
    case put("/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/@me", "",
           headers: [{"authorization", "Bot #{bot_token}"}]
         ) do
      {:ok, _} ->
        :ok

      error ->
        Logger.warn(error)
    end
  end
end
