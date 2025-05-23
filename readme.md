# Code to Image

A plugin that converts code to image, while preserving neovim visual elements.

## Quickstart

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
  {
    "mactep/code_to_image.nvim",
    enabled = true,
    build = "npm i", -- needed for `print_method = "browser"`
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
then uses `wkhtmltopdf` or `node` to convert it to an image.

## Dependencies

- [wkhtmltopdf](https://wkhtmltopdf.org/) or [node](https://nodejs.org/)
- [fastfetch](https://github.com/fastfetch-cli/fastfetch) (optional, used to detect the current font more reliably)

## Caveats

- Big files are unreadable
- Wide features such as folding may render the image too wide

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

# Examples

## Catppuccin

![image](https://github.com/user-attachments/assets/aba087ca-c43b-4eeb-807d-3322630d4fd0)

## Gruvbox material

![image](https://github.com/user-attachments/assets/b1349a2e-37e4-4b33-b04e-109c4fce3f75)

## Gruvbox

![image](https://github.com/user-attachments/assets/47ed2517-09a6-43a4-a7f7-8d335b3c118e)

Note: the outline color ended up being the same as the background

## nodic.nvim

![image](https://github.com/user-attachments/assets/4fdaf301-f830-45b8-b567-02834cf6e132)

