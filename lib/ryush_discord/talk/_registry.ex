defmodule RyushDiscord.Talk.TalkRegistry do
  @moduledoc false

  alias RyushDiscord.Guild

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_ignore) do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  @doc """
  See if the talk exists on registry
  """
  @spec exists?(Guild.t) :: true | false
  def exists?(guild) do
    case Registry.lookup(__MODULE__, {guild.channel_id, guild.user_id}) do
      [] ->
        false

      _ ->
        true
    end
  end

  @doc """
  Get the server name

  Used to create and find the guild servers through the `RyushDiscord.Guild.GuildRegistry`
  """
  @spec get_name(Guild.t()) :: {:via, Registry, {__MODULE__, {binary, binary}}}
  def get_name(guild) do
    {:via, Registry, {__MODULE__, {guild.channel_id, guild.user_id}}}
  end
end
