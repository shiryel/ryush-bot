# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushExternal.E621 do
  @moduledoc """
  Functions to get the E621 API
  """
  use Tesla

  require Logger

  plug Tesla.Middleware.BaseUrl, "https://e621.net/"
  plug Tesla.Middleware.Headers, [{"user-agent", "Ryush/1.0"}]
  plug Tesla.Middleware.JSON

  defp ratings(ratings) do
    case ratings do
      ["safe"] ->
        "rating:safe+"

      ["questionable"] ->
        "rating:questionable+"

      ["explicit"] ->
        "rating:explicit+"

      ["safe", "questionable"] ->
        "-rating:explicit+"

      ["questionable", "explicit"] ->
        "-rating:safe+"

      ["safe", "explicit"] ->
        "-rating:questionable+"

      ["safe", "questionable", "explicit"] ->
        ""

      _ ->
        "rating:safe+"
    end
  end

  @default %{score_min: 50, ratings: ["safe"]}

  defp get_posts(tags, options, limit) do
    tags =
      tags
      |> Enum.filter(fn x -> String.match?(x, ~r/[[:alnum:]]+/) end)
      |> Enum.join("+")

    %{score_min: score_min, ratings: rating} = Enum.into(options, @default)

    url =
      "posts.json?tags=#{tags}+-flash+score:>=#{score_min}+#{ratings(rating)}order:random&limit=#{
        limit
      }"
      |> URI.encode()

    Logger.debug(url)

    case get(url) do
      {:ok,
       %Tesla.Env{
         body: %{
           "posts" => posts
         }
       }} ->
        results =
          posts
          |> Enum.filter(fn
            %{
              "file" => %{
                "url" => nil
              }
            } ->
              false

            %{
              "file" => %{
                "url" => _url
              },
              "id" => _id
            } ->
              true
          end)
          |> Enum.map(fn
            %{
              "file" => %{
                "url" => url
              },
              "id" => id
            } ->
              %{url: url, id: id}
          end)

        {:ok, %{results: results, found_size: length(results)}}

      {_, error} ->
        {:error, error}
    end
  end

  @doc """
  Get a random post of E6 using the tags especified
  """
  @spec get_random_post_urls([bitstring()], [{atom(), any()}]) ::
          {:ok, [%{url: bitstring(), id: bitstring()}]}
          | {:error, :tags_not_found}
          | {:error, any}
  def get_random_post_urls(tags, options \\ []) when is_list(tags) do
    case get_posts(tags, options, 2) do
      {:ok, %{results: results}} ->
        {:ok, results}

      {:error, _error} ->
        {:error, :tags_not_found}
    end
  end

  @doc """
  Get the quantity of posts on the tags
  """
  @spec get_quantity([bitstring()], [{atom(), any()}]) ::
          {:ok, integer()}
          | {:error, :tags_not_found}
          | {:error, any}
  def get_quantity(tags, options \\ []) when is_list(tags) do
    # 320 is the limit of the API
    case get_posts(tags, options, 320) do
      {:ok, %{found_size: found_size}} ->
        {:ok, found_size}

      {:error, _error} ->
        {:error, :tags_not_found}
    end
  end
end
