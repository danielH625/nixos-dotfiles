-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	-- hl.exec_cmd(terminal)
	-- hl.exec_cmd("nm-applet")
	-- hl.exec_cmd("waybar & hyprpaper & firefox")
	-- hl.exec_cmd("waybar & hyprpaper & hypridle")
	hl.exec_cmd("uwsm app -- hyprpaper")
	hl.exec_cmd("uwsm app -- hypridle")
	hl.exec_cmd("uwsm app -- quickshell --path /home/danil/.config/quickshell/shell.qml")
	hl.exec_cmd("uwsm app -- bash /home/danil/.config/quickshell-lock/run-daemon.sh")
end)
