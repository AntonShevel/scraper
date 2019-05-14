defmodule Scraper.Parser do
  alias __MODULE__
  alias Scraper.Product
  alias Scraper.Parsers.ColdBlue

  @callback parse(page_pid :: pid()) :: {:ok, Product.t()} | {:error, term}

  defmacro __using__(_opts) do
    quote do
      @behaviour Parser
      alias Scraper.Product
      import Scraper.RemoteChrome
    end
  end

  def perform(page_pid, url) when is_pid(page_pid) do
    parser = get_parser(url)
    apply(parser, :parse, [page_pid])
  end

  defp get_parser(url) do
    case url do
      "https://www.coolblue.nl/product" <> _url -> ColdBlue
      _ -> raise "no parser defined for #{url}"
    end
  end
end
