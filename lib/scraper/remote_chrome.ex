defmodule Scraper.RemoteChrome do
  alias ChromeRemoteInterface.{Session, PageSession}
  alias ChromeRemoteInterface.RPC.{Page, DOM}

  @moduledoc """
  Facade for ChromeRemoteInterface
  """

  @timeout 10000

  @doc """
  Open a new chrome tab
  """
  @spec open_tab() :: {:ok, String.t(), pid()} | {:error, term()}
  def open_tab() do
    with {:ok, page} <- Session.new() |> Session.new_page(),
         {:ok, page_id} <- Map.fetch(page, "id"),
         {:ok, page_pid} <- PageSession.start_link(page),
         do: {:ok, page_id, page_pid}
  end

  @doc """
  Close tab by it's id
  """
  @spec close_tab(page_id :: String.t()) :: {:ok, Map.t()} | {:error, term()}
  def close_tab(page_id) do
    Session.new() |> Session.close_page(page_id)
  end

  @doc """
  Enable page for subscriptions and Subscribe for DOM ready event
  """
  @spec on_dom_ready(page_pid :: pid(), callback :: (Map.t() -> term())) :: term() | no_return()
  def on_dom_ready(page_pid, callback) do
    on_load_event = "Page.loadEventFired"

    with {:ok, _res} <- Page.enable(page_pid),
         :ok <- ChromeRemoteInterface.PageSession.subscribe(page_pid, on_load_event) do
      res =
        receive do
          {:chrome_remote_interface, "Page.loadEventFired", message} ->
            callback.(message)
        after
          @timeout -> raise "PageLoad callback timeout exceeded"
        end

      :ok = ChromeRemoteInterface.PageSession.unsubscribe(page_pid, on_load_event)

      res
    end
  end

  @doc """
  Open URL in given tab
  """
  @spec navigate_url(page_pid :: pid(), url :: String.t()) :: {:ok, Map.t()} | {:error, any()}
  def navigate_url(page_pid, url) do
    ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{url: url})
  end

  @doc """
  Get root document node id
  """
  @spec get_root_node_id(page_pid :: pid()) :: {:ok, String.t()} | {:error, any()}
  def get_root_node_id(page_pid) do
    with {:ok, res} <- ChromeRemoteInterface.RPC.DOM.getDocument(page_pid),
         do: {:ok, res["result"]["root"]["nodeId"]}
  end

  @doc """
  Find node by CSS selector
  """
  @spec get_node(
          page_pid :: pid(),
          root_node_id :: String.t(),
          selector :: String.t(),
          depth :: integer()
        ) :: {:ok, Map.t()} | {:error, any()}
  def get_node(page_pid, root_node_id, selector, depth \\ 1) do
    with {:ok, res} <- DOM.querySelector(page_pid, %{nodeId: root_node_id, selector: selector}),
         node_id <- get_in(res, ["result", "nodeId"]),
         {:ok, res} <- DOM.describeNode(page_pid, %{nodeId: node_id, depth: depth}),
         node <- get_in(res, ["result", "node"]),
         do: {:ok, node}
  end

  @doc """
  Find all nodes by CSS selector
  """
  @spec get_nodes(
          page_pid :: pid(),
          root_node_id :: String.t(),
          selector :: String.t(),
          depth :: integer()
        ) :: {:ok, [Map.t()]} | {:error, any()} | no_return
  def get_nodes(page_pid, root_node_id, selector, depth \\ 1) do
    with {:ok, res} <-
           DOM.querySelectorAll(page_pid, %{nodeId: root_node_id, selector: selector}),
         node_ids <- get_in(res, ["result", "nodeIds"]) do
      nodes =
        Enum.map(node_ids, fn node_id ->
          {:ok, res} = DOM.describeNode(page_pid, %{nodeId: node_id, depth: depth})
          get_in(res, ["result", "node"])
        end)

      {:ok, nodes}
    end
  end

  @doc """
  Get text from node child
  """
  @spec get_node_text(node :: Map.t()) :: {:ok, String.t()} | {:error, term()}
  def get_node_text(node) do
    with {:ok, [text_node | _]} <- Map.fetch(node, "children") do
      text = String.trim(text_node["nodeValue"])
      {:ok, text}
    end
  end

  @doc """
  Get attribute from the given node
  """
  @spec get_node_attribute(node :: Map.t(), attr_name :: String.t()) ::
          {:ok, String.t()} | {:error, any()}
  def get_node_attribute(node, attr_name) do
    with {:ok, attrs} <- Map.fetch(node, "attributes") do
      attrs
      |> Enum.chunk_every(2)
      |> Enum.find(fn [name, _value] -> name == attr_name end)
      |> case do
        nil -> {:error, :attr_not_found}
        [_name, value] -> {:ok, value}
      end
    end
  end
end
