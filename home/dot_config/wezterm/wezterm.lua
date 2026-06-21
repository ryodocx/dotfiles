local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- OS Detection
local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_mac = wezterm.target_triple:find("apple") ~= nil

-- Default shell setup (WSL on Windows, native zsh on macOS)
if is_windows then
  config.default_prog = { 'wsl.exe', '--cd', '~' }
end

-- Fonts: UDEV Gothic 35NF with OS native UD font fallback
config.font = wezterm.font_with_fallback({
  { family = "UDEV Gothic 35NF", weight = "Regular" },
  is_mac and "Hiragino Sans" or "BIZ UD Gothic",
  "Segoe UI Emoji",
})
config.font_size = 12.0
config.line_height = 1.1

-- Enable IME inline drawing
config.use_ime = true

-- Color Scheme
config.color_scheme = 'Gruvbox Dark (Gogh)'

-- Window styling
config.window_background_opacity = 0.95
config.text_background_opacity = 1.0

return config
