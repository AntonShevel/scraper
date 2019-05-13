defmodule Scraper do
  @moduledoc """
  Documentation for Scraper.
  """

  @timeout 50000

  @doc """
  Hello world.

  ## Examples

      iex> Scraper.hello()
      :world
  Scraper.parse(["https://www.coolblue.nl/product/812989/lenovo-yoga-530-14ikb-81ek00hwmh.html"])
  """
  def parse(urls) do
    urls
    |> Enum.map(&async_parse_url/1)
    |> Enum.each(&await_response/1)
  end

  defp async_parse_url(url) do
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid -> GenServer.call(pid, {:parse, url}, @timeout) end,
        @timeout
      )
    end)
  end

  defp await_response(task) do
    task |> Task.await(@timeout) |> IO.inspect()
  end
end
