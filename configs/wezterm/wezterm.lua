-- WezTerm Configuration — DevOS
-- Catppuccin Mocha theme

local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 13.0

config.color_scheme = "Catppuccin Mocha"

config.window_background_opacity = 0.95
config.window_decorations = "RESIZE"
config.window_padding = {
  left = 8,
  right = 8,
  top = 4,
  bottom = 4,
}

config.enable_wayland = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false

config.cursor_blink_rate = 500
config.default_cursor_style = "BlinkingBar"

config.keys = {
  { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo "Clipboard" },
  { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom "Clipboard" },
  { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab "CurrentPaneDomain" },
  { key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentTab { confirm = false } },
  { key = "n", mods = "CTRL|SHIFT", action = wezterm.action.SpawnWindow },
}

return config
