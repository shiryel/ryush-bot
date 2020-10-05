defmodule RyushDiscord.Flow.FlowSupervisor do
  @moduledoc false

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a new flow server
  """
  @spec start_new(any) :: DynamicSupervisor.on_start_child()
  def start_new(server) do
    DynamicSupervisor.start_child(__MODULE__, server)
  end
end
