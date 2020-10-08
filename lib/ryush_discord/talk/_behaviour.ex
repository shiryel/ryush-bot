defmodule RyushDiscord.Talk.TalkBehaviour do
  @moduledoc """
  Defines a more intuitive way to work with the Talk server flow

  The `paw/5` and `paw/6` macros creates a `paw_run/4` that altomaticaly handles the return of the macros and defines the next flow, either calling another `paw_run/4` or returning the final result when receiving a `{:end, GuildServer.t(), TalkServer.t()}`
  """

  alias RyushDiscord.{Guild, Talk}
  alias Guild.GuildServer
  alias Talk.TalkServer

  @callback paw_run(
              name :: atom(),
              guild :: Guild.t(),
              guild_state :: GuildServer.t(),
              state :: TalkServer.t()
            ) :: {:end | atom(), GuildServer.t(), TalkServer.t()}

  defmacro __using__(_opts) do
    quote do
      alias RyushDiscord.Talk.TalkBehaviour
      @behaviour TalkBehaviour
      require TalkBehaviour
      import TalkBehaviour
    end
  end

  defmacro paw(name, guild, guild_state, state, [when: when_], do: code) do
    quote do
      def paw_run(unquote(name), unquote(guild), unquote(guild_state), unquote(state))
          when unquote(when_) do
        unquote(code)
        |> paw_result()
      end
    end
  end

  defmacro paw(name, guild, guild_state, state, do: code) do
    quote do
      def paw_run(unquote(name), unquote(guild), unquote(guild_state), unquote(state)) do
        unquote(code)
        |> paw_result()
      end
    end
  end

  def paw_result({:end, guild_state, state}) do
    {:stop, :normal, guild_state, state}
  end

  def paw_result({next_step, guild_state, state}) do
    {:reply, guild_state, %{state | step: next_step}}
  end
end
