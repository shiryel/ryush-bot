defmodule RyushDiscord.Guild.GuildBehaviour do
  @moduledoc """
  Defines a more intuitive way to work with the Guild server flow

  The `paw/5` and `paw/6` macros creates a `paw_run/4` that altomaticaly handles the return of the macros and defines the next flow, either calling another `paw_run/4` or returning the final result when receiving a `{:end, GuildServer.t()}`
  """

  alias RyushDiscord.Guild
  alias Guild.GuildServer

  @callback paw_run(
              security :: atom(),
              name :: atom(),
              guild :: Guild.t(),
              state :: GuildServer.t()
            ) :: {atom(), atom(), Guild.t(), GuildServer.t()} | {:end, GuildServer.t()}

  defmacro __using__(_opts) do
    quote do
      alias RyushDiscord.Guild.GuildBehaviour

      @behaviour GuildBehaviour

      require GuildBehaviour
      import GuildBehaviour
    end
  end

  @doc """
  The paws are a sintax suggar to define the flux of the code ;)
  """
  @spec paw(atom(), atom(), Guild.t(), GuildServer.t(), [when: term()], do: term()) :: Macro.t()
  defmacro paw(security, name, guild, state, [when: when_], do: code) do
    quote do
      def paw_run(unquote(security), unquote(name), unquote(guild), unquote(state))
          when unquote(when_) do
        unquote(code)
        |> paw_result(__MODULE__)
      end
    end
  end

  @doc """
  The paws are a sintax suggar to define the flux of the code ;)
  """
  @spec paw(atom(), atom(), Guild.t(), GuildServer.t(), do: term()) :: Macro.t()
  defmacro paw(security, name, guild, state, do: code) do
    quote do
      def paw_run(unquote(security), unquote(name), unquote(guild), unquote(state)) do
        unquote(code)
        |> paw_result(__MODULE__)
      end
    end
  end

  @doc """
  [INTERNAL] used to handle the `paw/5` and `paw/6` result inside the `paw_run/4`
  """
  @spec paw_result(
          {atom(), atom(), %Guild{}, %GuildServer{}} | {:end, %GuildServer{}},
          module()
        ) ::
          {atom(), atom(), Guild.t(), GuildServer.t()} | {atom(), GuildServer.t()}
  def paw_result({security, name, guild, state}, module) do
    apply(module, :paw_run, [security, name, guild, state])
  end

  def paw_result({:end, state}, _module) do
    {:noreply, state}
  end
end
