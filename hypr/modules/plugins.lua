--------------------------------------------------------------------------------
-- HYPRGLASS LUA CONFIGURATION
--------------------------------------------------------------------------------

-- Guard check to ensure Hyprglass is loaded before applying settings
if hl.plugin and hl.plugin.hyprglass then
  local hg = hl.plugin.hyprglass

  -- Global Hyprglass Settings
  hg.config({
    default_theme = "dark",     -- "dark" or "light"
    default_preset = "glass",    -- "glass", "frosted", or "lens"
    layers = {
      enabled = 1,              -- Enable glass rendering on layer surfaces (bars/widgets)
    },
  })

  ------------------------------------------------------------------------------
  -- LAYER SURFACES (Quickshell, Eww, Bars, Menus)
  ------------------------------------------------------------------------------
  -- Apply Liquid Glass effect to Quickshell
  hg.layer("quickshell", {
    preset = "glass",
    mask_threshold = 0.70,
  })

  -- Apply Liquid Glass effect to Eww and Notifications
  hg.layer("eww")
  hg.layer("swaync")
  hg.layer("rofi")  
  hg.layer("kitty")
end