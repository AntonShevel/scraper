defmodule Scraper.Worker do
  use GenServer
  alias Scraper.RemoteChrome

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  @impl true
  def init(_) do
    {:ok, page_id, page_pid} = RemoteChrome.open_tab()
    initial_state = %{page_id: page_id, page_pid: page_pid}
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:parse, url}, _from, %{page_pid: page_pid} = state) do
    RemoteChrome.navigate_url(page_pid, url)

    res =
      RemoteChrome.on_dom_ready(page_pid, fn _message ->
        Scraper.Parser.perform(page_pid, url)
      end)

    {:reply, res, Map.put(state, :url, url)}
  end

  @impl true
  def terminate(_reason, %{page_id: page_id}) do
    Scraper.RemoteChrome.close_tab(page_id)
  end
end
