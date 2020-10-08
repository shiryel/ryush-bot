defmodule RyushDiscord.Talk.TalkBehaviour do
  alias RyushDiscord.{Guild, Talk}
  alias Guild.GuildServer
  alias Talk.TalkServer

  @callback _paw_start_(
              guild :: Guild.t(),
              guild_state :: GuildServer.t(),
              state :: TalkServer.t()
            ) :: {:stop | atom(), GuildServer.t(), TalkServer.t()}

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
      def unquote(String.to_atom("_paw_" <> Atom.to_string(name) <> "_"))(unquote(guild), unquote(guild_state), unquote(state)) when unquote(when_) do
        unquote(code)
      end
    end
  end

  defmacro paw(name, guild, guild_state, state, do: code) do
    quote do
      def unquote(String.to_atom("_paw_" <> Atom.to_string(name) <> "_"))(unquote(guild), unquote(guild_state), unquote(state)) do
        unquote(code)
      end
    end
  end
end
