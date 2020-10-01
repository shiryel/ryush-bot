defmodule Ryush.DiscordTest do
  use Ryush.DataCase

  alias Ryush.Discord

  describe "guilds" do
    alias Ryush.Discord.Guild

    @valid_attrs %{bot_channel_id: "some bot_channel_id", snowflake: "some snowflake"}
    @update_attrs %{bot_channel_id: "some updated bot_channel_id", snowflake: "some updated snowflake"}
    @invalid_attrs %{bot_channel_id: nil, snowflake: nil}

    def guild_fixture(attrs \\ %{}) do
      {:ok, guild} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Discord.create_guild()

      guild
    end

    test "list_guilds/0 returns all guilds" do
      guild = guild_fixture()
      assert Discord.list_guilds() == [guild]
    end

    test "get_guild!/1 returns the guild with given id" do
      guild = guild_fixture()
      assert Discord.get_guild!(guild.id) == guild
    end

    test "create_guild/1 with valid data creates a guild" do
      assert {:ok, %Guild{} = guild} = Discord.create_guild(@valid_attrs)
      assert guild.bot_channel_id == "some bot_channel_id"
      assert guild.snowflake == "some snowflake"
    end

    test "create_guild/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Discord.create_guild(@invalid_attrs)
    end

    test "update_guild/2 with valid data updates the guild" do
      guild = guild_fixture()
      assert {:ok, %Guild{} = guild} = Discord.update_guild(guild, @update_attrs)
      assert guild.bot_channel_id == "some updated bot_channel_id"
      assert guild.snowflake == "some updated snowflake"
    end

    test "update_guild/2 with invalid data returns error changeset" do
      guild = guild_fixture()
      assert {:error, %Ecto.Changeset{}} = Discord.update_guild(guild, @invalid_attrs)
      assert guild == Discord.get_guild!(guild.id)
    end

    test "delete_guild/1 deletes the guild" do
      guild = guild_fixture()
      assert {:ok, %Guild{}} = Discord.delete_guild(guild)
      assert_raise Ecto.NoResultsError, fn -> Discord.get_guild!(guild.id) end
    end

    test "change_guild/1 returns a guild changeset" do
      guild = guild_fixture()
      assert %Ecto.Changeset{} = Discord.change_guild(guild)
    end
  end
end
