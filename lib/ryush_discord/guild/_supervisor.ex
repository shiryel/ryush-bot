defmodule RyushDiscord.Guild.GuildSupervisor do
  @moduledoc false

  alias RyushDiscord.Guild
  alias Guild.GuildServer

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a new `RyushDiscord.Guild.GenServer`
  """
  @spec start_new(Guild.t()) :: DynamicSupervisor.on_start_child()
  def start_new(guild) do
    DynamicSupervisor.start_child(__MODULE__, {GuildServer, guild: guild})
  end
end
