defmodule RyushExternal.E621 do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://e621.net/"
  plug Tesla.Middleware.Headers, [{"user-agent", "Ryush/1.0"}]
  plug Tesla.Middleware.JSON

  @default %{score_min: 50, rating: "safe"}
  @doc """
  Get a random post of E6 using the tags especified
  """
  @spec get_random_post_url([bitstring()], [{atom(), any()}]) ::
          {:ok, bitstring()} | {:error, :tags_not_found} | {:error, any}
  def get_random_post_url(tags, options \\ []) when is_list(tags) do
    tags =
      tags
      |> Enum.filter(fn x -> String.match?(x, ~r/[[:alnum:]]+/) end)
      |> Enum.join("+")

    %{score_min: score_min, rating: rating} = Enum.into(options, @default)

    url = "posts.json?tags=#{tags}+-flash+score:>=#{score_min}+rating:#{rating}+order:random&limit=1"
          |> URI.encode()

    case get(url) do
      {:ok,
       %Tesla.Env{
         body: %{
           "posts" => [
             %{
               "file" => %{
                 "url" => url
               }
             }
           ]
         }
       }} ->
        {:ok, url}

      {:ok, %Tesla.Env{body: %{"posts" => []}}} ->
        {:error, :tags_not_found}

      {_, error} ->
        {:error, error}
    end
  end
end
