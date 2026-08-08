-- Vague minimal Hyprland config
-- Requires Hyprland 0.56+ (Lua config)

------------------
---- MONITORS ----
------------------

hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "1.2",
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
local fileManager = "nemo"
local menu = "rofi"
local browser = "firefox"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("mako")
	-- clipboard manager: watch text + image clipboard, persist into cliphist
	-- (text-only watchers die with the source app; this keeps the clipboard alive)
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	-- awww-daemon delayed: its cache-restore commit can be dropped by the
	-- startup page-flip race ("drm: Cannot commit when a page-flip is awaiting"),
	-- leaving the wallpaper black until a runtime re-commit.
	hl.exec_cmd("sh -c 'sleep 3 && awww-daemon'")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Vague palette
local bg = "0x141415"
local fg = "0xcdcdcd"
local fgDim = "0x606079"

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,

		border_size = 2,

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

		active_opacity = 0.9,
		inactive_opacity = 0.87,

		shadow = {
			enabled = true,
			range = 10,
			render_power = 2,
			color = 0xee000000,
		},

		blur = {
			enabled = true,
			size = 6,
			passes = 3,
			vibrancy = 0.0,
		},
	},

	animations = {
		enabled = true,
	},
})

-- Default curves and animations
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.config({
	dwindle = {
		preserve_split = true,
	},
})

hl.config({
	master = {
		new_status = "master",
	},
})

hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})

----------------
----  MISC  ----
----------------

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
})

---------------
---- INPUT ----
---------------

hl.config({
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

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local secondMod = "SUPER + SHIFT"

-- Launch
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu .. " -show drun"))
hl.bind(secondMod .. " + Space", hl.dsp.exec_cmd(menu .. " -show run"))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("/home/maul/.local/bin/wallpaper next"))

-- Window management
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(secondMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("/home/maul/.local/bin/clipboard-pick"))
hl.bind(secondMod .. " + V", hl.dsp.exec_cmd("/home/maul/.local/bin/clipboard-pick delete"))
hl.bind(secondMod .. " + BackSpace", hl.dsp.exec_cmd("/home/maul/.local/bin/clipboard-pick clear"))

-- Move focus (vim)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Move windows (vim)
hl.bind(secondMod .. " + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(secondMod .. " + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(secondMod .. " + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(secondMod .. " + L", hl.dsp.window.move({ direction = "right" }))

-- Workspaces
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Cycle used workspaces (Windows-style)
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("/home/maul/.local/bin/ws-cycle next"))
hl.bind(secondMod .. " + Tab", hl.dsp.exec_cmd("/home/maul/.local/bin/ws-cycle prev"))

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- System actions
hl.bind(secondMod .. " + Q", hl.dsp.exec_cmd("wleave"))

-- Screenshots
-- wl-copy puts the shot on the live clipboard; the image watcher stores history.
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | wl-copy -t image/png'))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grim - | wl-copy -t image/png"))

-- Laptop multimedia keys
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("/home/maul/.local/bin/osd-volume up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("/home/maul/.local/bin/osd-volume down"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("/home/maul/.local/bin/osd-volume mute"), { locked = true, repeating = true })
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("/home/maul/.local/bin/osd-volume mic"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("/home/maul/.local/bin/osd-brightness up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("/home/maul/.local/bin/osd-brightness down"),
	{ locked = true, repeating = true }
)

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

local suppressMaximizeRule = hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

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
	name = "float-opaque",
	match = { float = true },

	opaque = true,
})

hl.window_rule({
	name = "rofi-float",
	match = { class = "rofi" },

	float = true,
	border_size = 0,
	rounding = 0,
})

hl.window_rule({
	name = "wleave-float",
	match = { class = "wleave" },

	float = true,
	border_size = 0,
	rounding = 0,
})

hl.layer_rule({
	name = "wleave-glass",
	match = { namespace = "wleave" },
	blur = true,
	ignore_alpha = 0.1,
})

hl.layer_rule({
	name = "waybar-glass",
	match = { namespace = "waybar" },
	blur = true,
	ignore_alpha = 0.1,
})

hl.layer_rule({
	name = "mako-glass",
	match = { namespace = "notifications" },
	blur = true,
	ignore_alpha = 0.1,
})

hl.window_rule({
	name = "float-btop",
	match = { class = "btop" },

	float = true,
	size = { 900, 600 },
	move = { "monitor_w - 914", "40" },
})

hl.window_rule({
	name = "float-bluetui",
	match = { class = "bluetui" },

	float = true,
	size = { 800, 600 },
	move = { "monitor_w - 814", "40" },
})

hl.window_rule({
	name = "float-wifitui",
	match = { class = "wifitui" },

	float = true,
	size = { 800, 600 },
	move = { "monitor_w - 814", "40" },
})
