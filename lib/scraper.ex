defmodule Scraper do
  @timeout 50000

  @doc """
  Returns result as array of structs

  Example:
    Scraper.parse(["https://www.coolblue.nl/product/812989/lenovo-yoga-530-14ikb-81ek00hwmh.html"])
  """
  def parse(urls) do
    urls
    |> Enum.map(&async_parse_url/1)
    |> Enum.map(&await_response/1)
  end

  @doc """
  Returns current process PID only

  Example:
    urls = ["https://www.coolblue.nl/product/812989/lenovo-yoga-530-14ikb-81ek00hwmh.html"]
    {:ok, pid} = Scraper.start_link(urls: urls)
  """
  def start_link(urls: urls) do
    Enum.map(urls, &async_parse_url/1)
    {:ok, self()}
  end

  defp async_parse_url(url) do
    Task.async(fn ->
      parse_url(url)
    end)
  end

  defp await_response(task) do
    Task.await(task, @timeout)
  end

  defp parse_url(url) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, {:parse, url}, @timeout) end,
      @timeout
    )
  end
end
