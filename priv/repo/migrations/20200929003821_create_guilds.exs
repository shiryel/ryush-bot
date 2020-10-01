defmodule Ryush.Repo.Migrations.CreateGuilds do
  use Ecto.Migration

  def change do
    create table(:guilds) do
      add :snowflake, :string
      add :bot_channel_id, :string

      timestamps()
    end

  end
end
