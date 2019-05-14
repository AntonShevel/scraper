defmodule Scraper.Product do
  alias __MODULE__
  @derive [Poison.Encoder]

  @enforce_keys [:title, :rating, :reviews_count, :images, :price]

  @type t :: %Product{
          title: String.t()
        }

  defstruct @enforce_keys
end
