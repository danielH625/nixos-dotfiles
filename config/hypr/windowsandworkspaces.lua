-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

hl.window_rule({
	-- Ignore maximize requests from all apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

hl.layer_rule({
	match = { namespace = "waybar" },
	blur = false,
	no_anim = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-- hl.layer_rule({
-- 	name = "rofi-dropdown",
-- 	match = { namespace = "rofi" },
-- 	animation = "slide bottom",
-- 	dim_around = true,
-- })

hl.window_rule({
	name = "satty-float",
	match = { namespace = "satty" },
	float = true,
	center = false,
})

hl.window_rule({
	name = "brave-start-full",
	match = { namespace = "barve-browser" },
	float = false,
	center = true,
})

-- hl.layer_rule({
-- 	name = "swaync-dropdown",
-- 	match = { namespace = "swaync-control-center" },
-- 	animation = "slide top",
-- })

hl.window_rule({
	name = "float_satty",
	match = {
		class = "com.gabm.satty",
	},
	float = true,
	size = {
		"monitor_w * 0.8",
		"monitor_h * 0.8",
	},
	center = true,
})

hl.window_rule({
	name = "floating_workspace",
	match = {
		workspace = "5",
	},
	float = true,
	size = "800 600",
	center = true,
})

hl.window_rule({
	name = "float_gtk_file_picker",
	match = {
		initial_class = "^xdg-desktop-portal-gtk$",
	},
	float = true,
	size = {
		"monitor_w * 0.6",
		"monitor_h * 0.6",
	},
	center = true,
})

hl.window_rule({
	name = "pocket-settings",
	match = {
		class = "^(org\\.quickshell)$",
		title = "^(Ajustes)$",
	},
	float = true,
	size = "monitor_w*0.9 monitor_h*0.8",
	center = true,
})

-- hl.window_rule({
-- 	name = "float_nmtui",
-- 	match = {
-- 		initial_title = "^nmtui$",
-- 	},
-- 	float = true,
-- 	size = {
-- 		"monitor_w * 0.8",
-- 		"monitor_h * 0.8",
-- 	},
-- 	center = true,
-- })
