vim.api.nvim_create_user_command(
  "CodeToImage",
  function(args)
    require("code_to_image").convert({ args.line1, args.line2 })
  end,
  { bar = true, nargs = "?", range = "%" }
)
