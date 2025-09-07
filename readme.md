# Code to Image

A plugin that converts code to image, while preserving neovim visual elements.

## Quickstart

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
  {
    "mactep/code_to_image.nvim",
    enabled = true,
    build = "go build -o cdp", -- needed for print method "browser"
    config = true,
    cmd = "CodeToImage",
    keys = {
      {
        "<leader>ss",
        function()
          require("code_to_image").convert()
        end,
        mode = "n",
        { desc = "Convert whole file to image", silent = true, noremap = true },
      },
      {
        "<leader>ss",
        function()
          require("code_to_image").visual_convert()
        end,
        mode = "v",
        { desc = "Convert selection to image", silent = true, noremap = true },
      },
    },
  },
```

## How it works

It uses neovim's `TOhtml` to generate the html representation of the editor and
then uses `chromedp`, `wkhtmltopdf` or `servo` to convert it to an image.

## Dependencies

- [wkhtmltopdf](https://wkhtmltopdf.org/) or [node](https://nodejs.org/)
- [fastfetch](https://github.com/fastfetch-cli/fastfetch) (optional, used to detect the current font more reliably)

## Caveats

- Big files are unreadable
- Wide features such as folding may render the image too wide
- Does not seem to work with LSP tokens;

## Options

Every option and its default value:

```lua
{
  debug = false,
  print_method = "browser",
  browser = "",
  colors = {
    outline = "",
    background = "",
    foreground = "",
  },
  font = {
    family = "",
  },
}
```

## TODO

### Test with a headless browser for faster print times

```google-chrome-stable --remote-debugging-port=9222 --user-data-dir=<nvim-temp-dir>/remote-debug-profile --headless```

Needs to adapt the cdp binary to do:

```go
allocatorCtx, cancel := chromedp.NewRemoteAllocator(
    context.Background(),
    "ws://127.0.0.1:9222/",
)
defer cancel()

ctx, cancel := chromedp.NewContext(allocatorCtx)
defer cancel()
```

### Test servo

Servo is a fast alternative to opening a full fledged browser, but the
screenshot currently takes the whole page, meaning that it'll have white gaps
at the right and the bottom.

Setting the browser height and width to fit the content perfectly would be the
best approach, but it seems to be unreliable
