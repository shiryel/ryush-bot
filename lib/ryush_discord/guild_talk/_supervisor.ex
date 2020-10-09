defmodule RyushDiscord.GuildTalk.TalkSupervisor do
  @moduledoc false

  alias RyushDiscord.Guild
  alias RyushDiscord.GuildTalk.TalkServer

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a new `RyushDiscord.Guild.Talk.TalkServer`
  """
  @spec start_new(Guild.t(), atom()) :: DynamicSupervisor.on_start_child()
  def start_new(guild, about) do
    DynamicSupervisor.start_child(__MODULE__, {TalkServer, guild: guild, about: about})
  end
end
