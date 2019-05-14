defmodule Scraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    size = Application.fetch_env!(:scraper, :worker_count)

    poolboy_config = [
      {:name, {:local, :worker}},
      {:worker_module, Scraper.Worker},
      {:size, size},
      {:max_overflow, 0}
    ]

    # List all child processes to be supervised
    children = [
      :poolboy.child_spec(:worker, poolboy_config)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scraper.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
