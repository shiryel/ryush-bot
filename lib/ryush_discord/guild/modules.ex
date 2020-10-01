defmodule RyushDiscord.Guild.Modules do
  alias RyushDiscord.Guild

  @callback guild_process(guild :: Guild.t(), state :: term) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason :: term(), new_state}
            when new_state: term()

  @callback talk_process(name :: term, guild :: Guild.t(), guild_state :: term, state :: term) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason :: term(), new_state}
            when new_state: term()

  @modules [__MODULE__.Start]

  defmacro __using__(_opts) do
    for x <- @modules do
      quote do
        import unquote(x)
      end
    end

    quote do
      @before_compile RyushDiscord.Guild.Modules
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def guild_process(guild, state) do
        {:noreply, state}
      end

      def talk_process(name, guild, guild_state, state) do
        {:noreply, state}
      end
    end
  end

  # not working
  #defp relevant_sub_modules do
  #  :code.all_loaded()
  #  |> Enum.map(&elem(&1, 0))
  #  |> Enum.filter(&String.starts_with?(Atom.to_string(&1), "#{__MODULE__}."))
  #end
end
