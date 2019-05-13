defmodule Scraper.Parsers.ColdBlue do
  alias Scraper.Parser
  use Parser

  @impl Parser
  def parse(page_pid) do
    {:ok, root_node_id} = get_root_node_id(page_pid)
    {:ok, title_node} = get_node(page_pid, root_node_id, "#js-product-scope > h1 > span")
    {:ok, title} = get_node_text(title_node)
    {:ok, rating} = get_rating(page_pid, root_node_id)
    {:ok, reviews_count} = get_reviews_count(page_pid, root_node_id)
    {:ok, price} = get_price(page_pid, root_node_id)
    {:ok, images} = get_image_urls(page_pid, root_node_id) |> IO.inspect

    # Should use decimal for prices
    %Product{
      title: title,
      rating: rating,
      reviews_count: reviews_count,
      images: images,
      price: price
    }
  end

  defp get_rating(page_pid, root_node_id) do
    selector =
      "#js-product-scope > div.product-page--title-links > div.review-rating.review-rating--large > div > a > div > span > meter"

    with {:ok, node} <- get_node(page_pid, root_node_id, selector),
         {:ok, rating_string} <- get_node_attribute(node, "value"),
         {rating, _} <- Float.parse(rating_string),
         do: {:ok, rating}
  end

  defp get_reviews_count(page_pid, root_node_id) do
    selector =
      "#js-product-scope > div.product-page--title-links > div.review-rating.review-rating--large > span > a"

    with {:ok, node} <- get_node(page_pid, root_node_id, selector),
         {:ok, reviews_count_string} <- get_node_text(node),
         {reviews_count, _} <- Integer.parse(reviews_count_string),
         do: {:ok, reviews_count}
  end

  # converts price from 1.029,- to float: 1029.0
  defp get_price(page_pid, root_node_id) do
    selector =
      "#js-product-scope > div:nth-child(3) > div > div.product-page--order.grid-unit-xs--col-12.grid-unit-m--col-6.grid-unit-xl--col-5.js-sticky-bar-trigger > div > div.grid-section-xs--gap-4.js-order-block > div.is-hidden.is-visible-from-size-m.js-desktop-order-block > div > div.is-hidden.is-visible-from-size-m > div:nth-child(1) > span.sales-price.js-sales-price > strong"

    with {:ok, node} <- get_node(page_pid, root_node_id, selector),
         {:ok, price_string} <- get_node_text(node),
         {price, _} <-
           price_string |> String.replace(".", "") |> String.replace(",", ".") |> Float.parse(),
         do: {:ok, price}
  end

  defp get_image_urls(page_pid, root_node_id) do
    with {:ok, images} <- get_nodes(page_pid, root_node_id, ".product-media-gallery__item-image") do
      image_urls = Enum.map(images, fn image ->
        {:ok, url} = get_node_attribute(image, "src")
        url
      end)

      {:ok ,image_urls}
    end
  end
end
