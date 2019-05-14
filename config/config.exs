# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :scraper,
  chrome_host: "localhost",
  chrome_port: 9222,
  worker_count: 5
