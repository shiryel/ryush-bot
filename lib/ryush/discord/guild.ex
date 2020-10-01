defmodule Ryush.Discord.Guild do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "guilds" do
    field :bot_channel_id, :string
    field :snowflake, :string

    timestamps()
  end

  @doc false
  def changeset(guild, attrs) do
    guild
    |> cast(attrs, [:snowflake, :bot_channel_id])
    |> validate_required([:snowflake, :bot_channel_id])
  end
end
