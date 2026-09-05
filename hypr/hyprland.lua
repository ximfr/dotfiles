--------------------------------------------------------------------------------
-- MAIN HYPRLAND LUA CONFIGURATION ENTRYPOINT
--------------------------------------------------------------------------------

-- Environment Variables
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "candlemass")

-- Load Modular Sub-Configs
require("modules.autostart")
require("modules.decorations")
require("modules.input")
require("modules.binds")
require("modules.plugins")