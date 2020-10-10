defmodule Ryush.Mnesia do
  alias :mnesia, as: Mnesia

  require Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  def start_link(_opts) do
    Logger.info("Starting the Mnesia database...")
    Task.start_link(fn ->
      Mnesia.create_schema([node()])
      Mnesia.start()
    end)
  end
end
