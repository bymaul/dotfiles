hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1.2",
})

local terminal = "kitty"
local fileManager = "nemo"

hl.on("hyprland.start", function()
	hl.exec_cmd("qs")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QS_ICON_THEME", "Adwaita")

hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 6,

		border_size = 1,

		col = {
			active_border = { colors = { "rgba(cdcdcdcc)", "rgba(606079cc)" }, angle = 45 },
			inactive_border = "rgba(252530aa)",
		},

		resize_on_border = false,
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 0,
		rounding_power = 1,

		active_opacity = 0.97,
		inactive_opacity = 0.95,

		shadow = {
			enabled = true,
			range = 6,
			render_power = 2,
			color = "0xee000000",
		},

		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			vibrancy = 0.0,
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		preserve_split = true,
	},

	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},

	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "caps:escape",
		kb_rules = "",

		repeat_rate = 25,
		repeat_delay = 300,

		follow_mouse = 1,

		sensitivity = 0,

		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			scroll_factor = 0.8,
		},
	},
})

hl.curve("smoothOut", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "smoothOut" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "smoothOut" })
hl.animation({ leaf = "windows", enabled = true, speed = 5.5, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "fade", enabled = false })
hl.animation({ leaf = "layers", enabled = false })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "smoothOut", style = "slidefade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 6, bezier = "smoothOut" })

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

local mainMod = "SUPER"
local secondMod = "SUPER + SHIFT"

hl.bind(mainMod .. " + A", hl.dsp.global("qs-bar:Toggle Control Panel"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Space", hl.dsp.global("qs-bar:Toggle Launcher"))
hl.bind("ALT + Space", hl.dsp.global("qs-bar:Toggle Launcher"))
hl.bind(mainMod .. " + period", hl.dsp.global("qs-bar:Toggle Emoji"))
hl.bind(mainMod .. " + comma", hl.dsp.global("qs-bar:Settings"))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + D", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + Y", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.global("qs-bar:Toggle Clipboard"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(secondMod .. " + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(secondMod .. " + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(secondMod .. " + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(secondMod .. " + L", hl.dsp.window.move({ direction = "right" }))

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(secondMod .. " + Q", hl.dsp.global("qs-bar:Toggle Power Menu"))
hl.bind(secondMod .. " + C", hl.dsp.global("qs-bar:Toggle Caffeine"))
hl.bind(secondMod .. " + D", hl.dsp.global("qs-bar:Toggle DND"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.global("qs-bar:Lock Screen"), { locked = true })

hl.bind("Print", hl.dsp.global("qs-bar:Screenshot Area"))
hl.bind(mainMod .. " + Print", hl.dsp.global("qs-bar:Screenshot Full"))
hl.bind(secondMod .. " + Print", hl.dsp.global("qs-bar:Screenshot Window"))

hl.bind("XF86PowerOff", hl.dsp.global("qs-bar:Power Key"), { locked = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.global("qs-bar:Volume Up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.global("qs-bar:Volume Down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.global("qs-bar:Volume Mute"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.global("qs-bar:Mic Mute"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.global("qs-bar:Brightness Up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("qs-bar:Brightness Down"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.global("qs-bar:Media Next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.global("qs-bar:Media Play/Pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.global("qs-bar:Media Play/Pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.global("qs-bar:Media Previous"), { locked = true })

hl.window_rule({
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

hl.window_rule({
	name = "float-transparency",
	match = { float = true },
	opacity = "0.85 override 0.85 override",
})

hl.layer_rule({
	name = "qs-bar-glass",
	match = { namespace = "qs-bar" },
	blur = true,
	ignore_alpha = 0.1,
})

hl.layer_rule({
	name = "qs-notifications-glass",
	match = { namespace = "qs-notifications" },
	blur = true,
	ignore_alpha = 0.1,
	no_anim = true,
})

hl.layer_rule({
	name = "qs-picker-order",
	match = { namespace = "qs-screenshot-picker" },
	order = 10,
})

hl.layer_rule({
	name = "qs-notifications-order",
	match = { namespace = "qs-notifications" },
	order = 20,
})
