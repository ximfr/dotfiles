--------------------------------------------------------------------------------
-- DECORATIONS & TUNED BLUR SETTINGS
--------------------------------------------------------------------------------

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 20,
    border_size = 0, -- No colored borders
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 10,
    rounding_power = 2,

    active_opacity = 1.0,
    inactive_opacity = 1.0,

    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },

    -- Advanced Tuned Blur Settings
    blur = {
      enabled = true,
      size = 8,
      passes = 2,
      

      -- Color & Light Tuning
      brightness = 0.8,         -- Dark theme backdrop balance
      contrast = 1.8,           -- Higher contrast for rich vibrant colors
      vibrancy = 0.35,          -- Color saturation boost
      vibrancy_darkness = 0.35, -- Dark area saturation boost
      noise = 0.0,              -- Film grain (0.0 = clean)
    },
  },

  animations = {
    enabled = true,

    bezier = {
      "winIn, 0.1, 1.0, 0.1, 1.0",
      "winOut, 0.1, 1.0, 0.1, 1.0",
      "smoothOut, 0.5, 0, 0.99, 0.99",
      "layerOut, 0.23, 1, 0.32, 1",
    },

    animation = {
      "windowsIn, 1, 7, winIn, slide",
      "windowsOut, 1, 3, smoothOut, slide",
      "windowsMove, 1, 7, winIn, slide",
      "workspacesIn, 1, 8, winIn, slidevert",
      "workspacesOut, 1, 8, winOut, slidevert",
      "layersIn, 1, 10, winIn, slide",
      "layersOut, 1, 3, layerOut, popin 50%",
    },
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = -1,
    disable_hyprland_logo = false,
  },
})