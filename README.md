# Scraper

Get dependencies
```bash
mix deps.get
```

Run chrome with remote debugging enabled
```bash
chrome --remote-debugging-port=9222 --headless --disable-gpu
```

Run interactive console:
```bash
iex -S mix
```

Start scraper:
```elixir
urls = ["https://www.coolblue.nl/product/812989/lenovo-yoga-530-14ikb-81ek00hwmh.html"]
Scraper.parse(urls)
# or
{:ok, pid} = Scraper.start_link(urls: urls)
```
