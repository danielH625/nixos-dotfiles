-- Set programs that you use
local terminal = "kitty"
local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local screenshot_snippet = "hyprshot -m region --raw | satty --filename -"
-- local lock_screen = "pidof hyprlock || hyprlock"
local lock_screen = "loginctl lock-session"
local browser = "brave"
-- local waybar_reload = "pkill waybar; waybar &"
-- local fileManager = "dolphin"
-- local menu = "~/.config/rofi/type-2/launcher.sh"
-- local swaync = "swaync-client -t"

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
closeWindowBind:set_enabled(true)
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(lock_screen))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
-- hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(waybar_reload))
-- hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
-- hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu))
-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
-- hl.bind(
-- 	mainMod .. " + M",
-- 	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
-- )

-- Scrolling layout: column size
hl.bind(mainMod .. " + F", hl.dsp.layout("colresize +conf"))

-- Navigate horizontally between columns
hl.bind(mainMod .. " + H", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + L", hl.dsp.layout("focus r"))

-- Navigate vertically between windows
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move the current column left/right
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.layout("swapcol r"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
-- hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd(screenshot_snippet))

-- Notificaton menu
-- hl.bind(mainMod .. " + N ", hl.dsp.exec_cmd(swaync))

-- Quickshell Keybinds
hl.bind("SUPER + period", hl.dsp.global("quickshell:notch"))
hl.bind("SUPER + Space", hl.dsp.global("quickshell:launcher"))
hl.bind("SUPER + comma", hl.dsp.global("quickshell:settings"))
hl.bind("SUPER + SHIFT + period", hl.dsp.global("quickshell:system"))
hl.bind("SUPER + TAB", hl.dsp.global("quickshell:overview"))

hl.bind("SUPER + ALT + P", hl.dsp.global("quickshell:power"))
hl.bind("SUPER + ALT + C", hl.dsp.global("quickshell:calendar"))
hl.bind("SUPER + ALT + M", hl.dsp.global("quickshell:media")) -- Floating media player
hl.bind("SUPER + ALT + Space", hl.dsp.global("quickshell:actions")) -- Launcher in > actions mode
hl.bind("SUPER + ALT + N", hl.dsp.global("quickshell:network")) -- Wi-Fi
hl.bind("SUPER + ALT + B", hl.dsp.global("quickshell:bluetooth")) -- Bluetooth (needs BlueZ)
hl.bind("SUPER + ALT + D", hl.dsp.global("quickshell:dnd")) -- Do not disturb
hl.bind("SUPER + ALT + I", hl.dsp.global("quickshell:caffeine")) -- Keep awake
hl.bind("SUPER + N", hl.dsp.global("quickshell:notchstyle")) -- Notch / floating island
hl.bind("SUPER + W", hl.dsp.global("quickshell:bar")) -- Hide / show shell
hl.bind("SUPER + Escape", hl.dsp.global("quickshell:close")) -- Close notch panel

-- Open Settings directly to keyboard shortcuts
hl.bind("SUPER + F1", hl.dsp.global("quickshell:keybinds"))

-- Monitor configuration
hl.bind("SUPER + M", function()
	hl.exec_cmd("uwsm app -- kitty --class pocket-monitors --title 'Monitor configuration' hyprmoncfg")
end)

-- Open Settings directly to the wallpaper selector
hl.bind("SUPER + ALT + W", hl.dsp.global("quickshell:wallpapers"))
