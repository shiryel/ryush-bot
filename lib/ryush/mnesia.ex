# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

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
      # if not stoped, the create_schema will not work!
      Mnesia.stop()
      Mnesia.create_schema([node()])
      |> inspect
      |> Logger.info()
      Mnesia.start()
      |> inspect
      |> Logger.info()
    end)
  end
end
