local M = {}

M.opts = {
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

M._get_foreground_color = function()
  if M.opts.colors.foreground ~= "" then
    return M.opts.colors.foreground
  end

  local fg_color = vim.api.nvim_get_hl(0, { name = "Normal" }).fg

  return string.format("#%06x", fg_color)
end

M._get_background_color = function()
  if M.opts.colors.background ~= "" then
    return M.opts.colors.background
  end

  local bg_color = vim.api.nvim_get_hl(0, { name = "Normal" }).bg

  return string.format("#%06x", bg_color)
end

M._get_outline_color = function()
  if M.opts.colors.outline ~= "" then
    return M.opts.colors.outline
  end


  local hex_bg_color = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "IncSearch" }).bg)
  if hex_bg_color ~= M._get_background_color() then
    return hex_bg_color
  end

  return string.format("#%06x", vim.api.nvim_get_hl(0, { name = "PmenuSel" }).bg)
end

M._get_font = function()
  if M.opts.font.family ~= "" then
    return M.opts.font.family
  end

  -- if guifont is set, use that
  local guifont = vim.api.nvim_get_option_value("guifont", {})
  if guifont ~= "" then
    return guifont
  end

  -- NOTE: vim.system throws error if the command cannot be run

  -- let the heavy-lifters do the heavy lifting
  if vim.fn.executable("fastfetch") == 1 then
    local fastfetch = vim.fn.system("fastfetch --structure TerminalFont --logo none | cut -d ':' -f 2")
    if fastfetch ~= "" then
      return vim.trim(fastfetch)
    end
  end

  if vim.fn.executable("gsettings") == 1 then
    local gsettings_font = vim.fn.system("gsettings get org.gnome.desktop.interface monospace-font-name")
    if gsettings_font ~= "" then
      local trimmed = vim.trim(gsettings_font):gsub("'", "")
      local split = vim.split(trimmed, " ")
      table.remove(split)
      return table.concat(split, " ")
    end
  end

  return ""
end

M._update_html = function(html)
  local background_color = M._get_background_color()
  local foreground_color = M._get_foreground_color()
  local outline_color = M._get_outline_color()

  local bodyStyle = "body { margin: 0; color: " .. foreground_color .. "; }"
  local containerStyle = ".container { background-color: " .. outline_color .. "; padding: 5%; }"
  local preStyle = "pre { background-color: " ..
      background_color .. "; border-radius: 1rem; padding: 1rem 1rem 0 1rem; }"

  for i, line in pairs(html) do
    -- if line:match("^%s*%*%s*{") then
    --   html[i] = "* { font-family: " .. M._get_font() .. "; font-size: " .. M.opts.font.size .. "; }"
    -- end

    if line:match("^%s*body") then
      html[i] = bodyStyle .. containerStyle .. preStyle
    end

    if line:match("^%s*<pre>") then
      html[i] = "<div class='container'><pre>"
    end

    if line:match("^%s*</pre>") then
      html[i] = "</pre></div>"
    end
  end

  return html
end

M._max_line_length = function(range)
  if range == nil then
    range = { 1, vim.fn.line("$") }
  end

  local max_line_length = 0
  for i = range[1], range[2] do
    local line_length = vim.fn.strdisplaywidth(vim.fn.getline(i))
    if line_length > max_line_length then
      max_line_length = line_length
    end
  end
  return max_line_length
end

M._calculate_width = function(range)
  local max_line_length = M._max_line_length(range)
  local length_leeway = 4
  local height_width_ratio = 1.1
  max_line_length = math.floor((max_line_length + length_leeway) * height_width_ratio)
  local font_height = 12
  local width = max_line_length * font_height

  return width
end

-- TODO: there should be a better way of doing this
M._get_font_width = function()
  local font_height = 12
  local height_width_ratio = 1.1
  return font_height * height_width_ratio
end

M._copy_image_to_clipboard = function(input)
  if input == nil then
    print("no input to copy")
    return
  end

  if input.image_path ~= nil then
    if vim.fn.executable("xclip") == 1 then
      vim.fn.system("xclip -selection clipboard -t image/png -i < " .. input.image_path)
      return
    end

    if vim.fn.executable("wl-copy") == 1 then
      vim.fn.system("wl-copy -t image/png < " .. input.image_path)
      return
    end

    print("no clipboard tool found")
    return
  end

  if input.stdin ~= nil then
    if vim.fn.executable("xclip") == 1 then
      vim.system({ "xclip", "-selection", "clipboard", "-t", "image/png", "-i" }, { stdin = input.stdin })
      return
    end

    if vim.fn.executable("wl-copy") == 1 then
      vim.system({ "wl-copy", "-t", "image/png" }, { stdin = input.stdin })
      return
    end

    print("no clipboard tool found")
    return
  end
end


M._wkhtmltoimage_screenshot = function(html, opts)
  local width = opts.width or "0"

  if M.opts.debug then
    local outfile = vim.fn.tempname() .. ".html"
    vim.fn.writefile(html, outfile)
    vim.ui.open(outfile)
  end

  vim.system(
    { "wkhtmltoimage", "--width", width, "-", "-" },
    { stdin = html },
    function(out)
      M._copy_image_to_clipboard({ stdin = out.stdout })
    end
  )
end

function M._get_package_path()
  -- Path to this source file
  local source = string.sub(debug.getinfo(1, "S").source, 2)

  -- Path to the package root,
  return vim.fn.fnamemodify(source, ":p:h:h")
end

M._servo_screenshot = function(html, opts)
  local outfile = vim.fn.tempname() .. ".html"
  vim.fn.writefile(html, outfile)
  local screenshot_path = vim.fn.tempname() .. ".png"

  -- Convert file:// URL
  local url = "file://" .. outfile

  -- Calculate window size based on width and number of lines
  -- The width is in pixels, and we need to estimate height
  -- Let's assume each line is about 20 pixels tall (approximate for monospace font)
  -- Add some padding for the container
  local width = opts.width or 800
  -- Estimate number of lines from the HTML content
  -- Count the number of <span> tags which usually correspond to lines
  local line_count = 0
  for _ in table.concat(html):gmatch("<span") do
      line_count = line_count + 1
  end
  -- Add some extra height for padding and container
  local height = math.max((line_count * 20) + 100, 200)
  
  -- Run servo to capture the screenshot with specified window size
  local cmd = { 
      "servo", 
      "--headless", 
      "--output=" .. screenshot_path, 
      "--window-size=" .. math.floor(width) .. "," .. math.floor(height),
      url 
  }
  local out = vim.system(cmd):wait()

  if M.opts.debug then
    print("servo command:", vim.inspect(cmd))
    print("servo output:", vim.inspect(out))
    print("width:", width, "height:", height)
  end

  if out.code ~= 0 then
    print("servo screenshot failed:", out.stderr)
    return
  end

  -- Copy the screenshot to clipboard
  M._copy_image_to_clipboard({ image_path = screenshot_path })
end

M._browser_screenshot = function(html)
  local outfile = vim.fn.tempname() .. ".html"
  vim.fn.writefile(html, outfile)
  local outfile_base_path = vim.fn.fnamemodify(outfile, ":h")
  local screenshot_path = outfile_base_path .. "/screenshot.png"

  local package_path = M._get_package_path()

  -- absolute path to the plugin directory
  local index_js = package_path .. "/index.js"
  local cdp = package_path .. "/cdp"

  local browser
  if M.opts.browser ~= "" then
    if M.opts.debug then
      print("browser:", M.opts.browser)
    end

    browser = vim.trim(vim.fn.system("which " .. M.opts.browser))
    if M.opts.debug then
      print("browserPath:", browser)
    end
  end

  local cmd = { cdp, "-file", outfile, "-screenshot", screenshot_path }

  local out = vim.system(cmd, { env = { BROWSER = browser } }):wait()
  if M.opts.debug then
    print("out:", vim.inspect(out))
  end

  if out.code ~= 0 then
    print("screenshot failed:", out.stderr)
    return
  end
  M._copy_image_to_clipboard({ image_path = screenshot_path })
end

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

M.convert = function(range)
  local font = M._get_font()

  local html = require("tohtml").tohtml(
    0,
    {
      range = range,
      font = font,
    }
  )

  local width = M._calculate_width(range)

  M._update_html(html)

  print("M.opts.print_method == " .. M.opts.print_method)

  if M.opts.print_method == "wkhtmltoimage" then
    M._wkhtmltoimage_screenshot(html, { width = width })
    return
  end

  if M.opts.print_method == "browser" then
    M._browser_screenshot(html)
    return
  end

  if M.opts.print_method == "servo" then
    M._servo_screenshot(html, { width = width })
    return
  end
end

M.visual_convert = function()
  local range = { vim.fn.getpos("v")[2], vim.fn.getpos(".")[2] }
  -- sort the range
  local line1 = math.min(range[1], range[2])
  local line2 = math.max(range[1], range[2])

  M.convert({ line1, line2 })
end

return M
