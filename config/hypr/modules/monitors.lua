-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- hl.monitor({
-- 	output = "",
-- 	mode = "preferred",
-- 	position = "auto",
-- 	scale = "auto",
-- })
-- hl.monitor({
-- 	output = "eDP-1",
-- 	mode = "1920x1080@60",
-- 	position = "auto",
-- 	scale = "1.0",
-- })
-- hl.monitor({
-- 	output = "HDMI-A-1",
-- 	mode = "2560x1440@60",
-- 	position = "auto",
-- 	scale = "1.0",
-- })

hl.workspace_rule({ workspace = "1", persistent = true })
hl.workspace_rule({ workspace = "2", persistent = true })
hl.workspace_rule({ workspace = "3", persistent = true })
hl.workspace_rule({ workspace = "4", persistent = true })
hl.workspace_rule({ workspace = "5", persistent = true })

-- hl.bind("switch:on:Lid Switch", function()
-- 	hl.exec_cmd("hyprctl notify -1 5000 'rgb(ff0000)' 'Lid Closed'")
-- 	-- hl.monitor({ output = "eDP-1", disabled = true })
-- end)
--
-- hl.bind("switch:off:Lid Switch", function()
-- 	hl.exec_cmd("hyprctl notify -1 5000 'rgb(ff0000)' 'Lid Open'")
-- 	-- hl.monitor({ output = "eDP-1", disabled = false })
-- 	-- hl.exec_cmd([[
-- 	--        sh -c '
-- 	--            sleep 5
-- 	--            hyprctl reload config-only
-- 	--        '
-- 	--    ]])
-- 	hl.notification.create({
-- 		text = "External monitor connected",
-- 		timeout = 2000,
-- 		icon = "ok",
-- 	})
-- end)

local Mode = {
	UNDOCKED = 1,
	DOCKED = 2,
}

local applying = false
local currentMode = nil

local function applyMode()
	if applying then
		return
	end

	local newMode = hl.get_monitor("HDMI-A-1") ~= nil and Mode.DOCKED or Mode.UNDOCKED

	-- Don't do anything if we're already in the correct mode
	if newMode == currentMode then
		return
	end

	applying = true
	currentMode = newMode

	if newMode == Mode.DOCKED then
		-- Use HDMI only
		hl.monitor({
			output = "HDMI-A-1",
			mode = "2560x1440@60",
			position = "0x0",
			scale = 1,
			disabled = false,
		})

		hl.monitor({
			output = "eDP-1",
			disabled = true,
		})

		hl.notification.create({
			text = "Docked",
			timeout = 2000,
			icon = "ok",
		})
	else
		-- Use laptop only
		hl.monitor({
			output = "eDP-1",
			mode = "1920x1080@60",
			position = "0x0",
			scale = 1,
			disabled = false,
		})

		hl.monitor({
			output = "HDMI-A-1",
			disabled = true,
		})

		hl.notification.create({
			text = "Undocked",
			timeout = 2000,
			icon = "ok",
		})
	end

	-- Give Hyprland time to finish reconfiguring monitors
	hl.timer(function()
		applying = false
	end, {
		timeout = 500,
		type = "oneshot",
	})
end

hl.on("hyprland.start", applyMode)
hl.on("monitor.added", applyMode)
hl.on("monitor.removed", applyMode)
hl.on("monitor.layout_changed", applyMode)

-- Optional manual toggle
hl.bind("SUPER + M", applyMode)
