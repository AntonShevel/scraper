defmodule Scraper.Worker do
  use GenServer
  alias Scraper.RemoteChrome

  def start_link(_) do
    IO.inspect("WORKER START_LINK")
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
    IO.inspect(url, label: "handle call")
    IO.inspect(self(), label: "handle call")

    RemoteChrome.navigate_url(page_pid, url)
    #    Scraper.RemoteChrome.on_dom_ready(page_pid)
    #    selfff = self()
    #    :erlang.process_info(selfff, :message_queue_len) |> IO.inspect(label: "message_queue_len1")
    #
    #    res = receive do
    #            {:chrome_remote_interface, "Page.loadEventFired", _message} ->
    #              :erlang.process_info(selfff, :message_queue_len) |> IO.inspect(label: "message_queue_len2")
    #              Scraper.Parser.perform(page_pid, url) |> IO.inspect(label: "receive: perform")
    #
    #            _ ->
    #              raise "Unexpected message"
    #          end
    #
    #    foo = receive do
    #      {:chrome_remote_interface, "Page.loadEventFired", _message} -> :ok
    #      after 0 -> :ok
    #    end
    #
    #    :erlang.process_info(selfff, :message_queue_len) |> IO.inspect(label: "message_queue_len3")
    res =
      RemoteChrome.on_dom_ready(page_pid, fn _message ->
        Scraper.Parser.perform(page_pid, url)
      end)

    {:reply, res, Map.put(state, :url, url)}
  end

  @impl true
  def terminate(reason, %{page_id: page_id}) do
    IO.inspect(reason, label: "Terminating...")
    Scraper.RemoteChrome.close_tab(page_id)
  end

  #  @impl true
  #  def handle_call({:chrome_remote_interface, "Page.loadEventFired", _details}, _from, state) do
  #    IO.inspect "handle_call loadEvent"
  #
  #    {:reply, :ok, state}
  #  end
  #
  #  @impl true
  #  def handle_info({:chrome_remote_interface, "Page.loadEventFired", _details}, state) do
  #    IO.inspect "handle_info loadEvent"
  #    {:noreply, state}
  #  end
end
