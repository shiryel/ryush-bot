# Copyright (C) 2020 Shiryel
#
# You should have received a copy of the GNU Affero General Public License v3.0 along with this program. 

defmodule RyushExternal.E621 do
  @moduledoc """
  Functions to get the E621 API
  """
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://e621.net/"
  plug Tesla.Middleware.Headers, [{"user-agent", "Ryush/1.0"}]
  plug Tesla.Middleware.JSON

  @default %{score_min: 50, rating: "safe"}
  @doc """
  Get a random post of E6 using the tags especified
  """
  @spec get_random_post_urls([bitstring()], [{atom(), any()}]) ::
          {:ok, [%{url: bitstring(), id: bitstring()}]} | {:error, :tags_not_found} | {:error, any}
  def get_random_post_urls(tags, options \\ []) when is_list(tags) do
    tags =
      tags
      |> Enum.filter(fn x -> String.match?(x, ~r/[[:alnum:]]+/) end)
      |> Enum.join("+")

    %{score_min: score_min, rating: rating} = Enum.into(options, @default)

    url =
      "posts.json?tags=#{tags}+-flash+score:>=#{score_min}+rating:#{rating}+order:random&limit=50"
      |> URI.encode()

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

        {:ok, results}

      {_, error} ->
        {:error, error}
    end
  end
end
