defmodule Ryush.Discord do
  @moduledoc """
  The Discord context.
  """

  import Ecto.Query, warn: false
  alias Ryush.Repo

  alias Ryush.Discord.Guild

  @doc """
  Returns the list of guilds.

  ## Examples

      iex> list_guilds()
      [%Guild{}, ...]

  """
  def list_guilds do
    Repo.all(Guild)
  end

  @doc """
  Gets a single guild.

  Raises `Ecto.NoResultsError` if the Guild does not exist.

  ## Examples

      iex> get_guild!(123)
      %Guild{}

      iex> get_guild!(456)
      ** (Ecto.NoResultsError)

  """
  def get_guild!(id), do: Repo.get!(Guild, id)

  @doc """
  Creates a guild.

  ## Examples

      iex> create_guild(%{field: value})
      {:ok, %Guild{}}

      iex> create_guild(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_guild(attrs \\ %{}) do
    %Guild{}
    |> Guild.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a guild.

  ## Examples

      iex> update_guild(guild, %{field: new_value})
      {:ok, %Guild{}}

      iex> update_guild(guild, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_guild(%Guild{} = guild, attrs) do
    guild
    |> Guild.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a guild.

  ## Examples

      iex> delete_guild(guild)
      {:ok, %Guild{}}

      iex> delete_guild(guild)
      {:error, %Ecto.Changeset{}}

  """
  def delete_guild(%Guild{} = guild) do
    Repo.delete(guild)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking guild changes.

  ## Examples

      iex> change_guild(guild)
      %Ecto.Changeset{data: %Guild{}}

  """
  def change_guild(%Guild{} = guild, attrs \\ %{}) do
    Guild.changeset(guild, attrs)
  end
end
