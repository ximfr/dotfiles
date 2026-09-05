--------------------------------------------------------------------------------
-- AUTOSTART PROCESSES
--------------------------------------------------------------------------------

hl.on("hyprland.start", function()
  hl.exec_cmd("qs")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("sudo ydotoold")
  hl.exec_cmd("sleep 1 && sudo chmod 666 /tmp/.ydotool_socket")
  hl.exec_cmd("eww daemon")
  hl.exec_cmd("hyprctl plugin load ~/.config/hypr/hyprglass.so")
end)

hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"')
