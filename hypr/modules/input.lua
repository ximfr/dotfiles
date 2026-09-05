--------------------------------------------------------------------------------
-- INPUT & DEVICE CONFIGURATION
--------------------------------------------------------------------------------

hl.config({
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = false,
    },
  },

  gesture = {
    "3, horizontal, workspace",
  },
})

-- Per-Device Config
hl.device({
  name = "epic-mouse-v1",
  sensitivity = -0.5,
})
