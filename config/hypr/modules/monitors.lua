-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- hl.monitor({
-- 	output = "",
-- 	mode = "preferred",
-- 	position = "auto",
-- 	scale = "auto",
-- })
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@60",
	position = "auto",
	scale = "1",
})
hl.monitor({
	output = "HDMI-A-1",
	mode = "2560x1440@60",
	position = "auto",
	scale = "1.0",
})

hl.workspace_rule({ workspace = "1", persistent = true })
hl.workspace_rule({ workspace = "2", persistent = true })
hl.workspace_rule({ workspace = "3", persistent = true })
hl.workspace_rule({ workspace = "4", persistent = true })
hl.workspace_rule({ workspace = "5", persistent = true })

hl.bind("switch:on:Lid Switch", function()
	hl.exec_cmd("hyprctl notify -1 5000 'rgb(ff0000)' 'Lid Closed'")
	hl.monitor({ output = "eDP-1", disabled = true })
	hl.exec_cmd([[
        sh -c '
            sleep 1
            hyprctl reload config-only
        '
    ]])
end)

hl.bind("switch:off:Lid Switch", function()
	hl.exec_cmd("hyprctl notify -1 5000 'rgb(ff0000)' 'Lid Open'")
	hl.monitor({ output = "eDP-1", disabled = false })
	hl.exec_cmd([[
        sh -c '
            sleep 5
            hyprctl reload config-only
        '
    ]])
end)
