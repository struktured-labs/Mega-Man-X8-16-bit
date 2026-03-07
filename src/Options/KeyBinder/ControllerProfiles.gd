# Static controller profile data and helpers.
# Add new profiles by extending the PROFILES dictionary.

const PROFILE_CUSTOM := "PROFILE_CUSTOM"
const PROFILE_DEFAULT := "PROFILE_DEFAULT"
const PROFILE_STRUKTURED := "PROFILE_STRUKTURED"

const PROFILE_ORDER := [PROFILE_DEFAULT, PROFILE_STRUKTURED, PROFILE_CUSTOM]

# Each profile maps action -> Array of joypad event descriptors.
# Descriptor format: {"type": "button", "index": int}
#                 or {"type": "axis",   "index": int, "value": float}
# An empty array [] means "no joypad binding" (keyboard-only).
# The Default profile mirrors project.godot's built-in joypad mappings.
const PROFILES := {
	PROFILE_DEFAULT: {
		"fire":                 [{"type": "button", "index": 2}],
		"alt_fire":             [{"type": "button", "index": 3}],
		"jump":                 [{"type": "button", "index": 0}],
		"dash":                 [{"type": "button", "index": 4}],
		"move_left":            [{"type": "button", "index": 14}],
		"move_right":           [{"type": "button", "index": 15}],
		"move_up":              [{"type": "button", "index": 12}],
		"move_down":            [{"type": "button", "index": 13}],
		"analog_left":          [{"type": "axis", "index": 3, "value": -1.0}],
		"analog_right":         [{"type": "axis", "index": 3, "value": 1.0}],
		"analog_up":            [{"type": "axis", "index": 4, "value": -1.0}],
		"analog_down":          [{"type": "axis", "index": 4, "value": 1.0}],
		"reset_weapon":         [{"type": "button", "index": 10}],
		"select_special":       [{"type": "button", "index": 9}],
		"pause":                [{"type": "button", "index": 6}],
		"ui_accept":            [{"type": "button", "index": 2}],
		"weapon_select_left":   [{"type": "button", "index": 1}],
		"weapon_select_right":  [{"type": "button", "index": 5}],
	},
	PROFILE_STRUKTURED: {
		# 8BitDo Ultimate 2 Pro layout (xpad raw indices)
		# X=fire, Y=alt_fire, A=jump, LB+B=dash, RB=alt_fire(2nd)
		# R-stick=weapon wheel, R3=reset_weapon, D-pad+L-stick=movement
		# Back=pause, L3=select_special, no L2/R2
		"fire":                 [{"type": "button", "index": 2}],
		"alt_fire":             [{"type": "button", "index": 3},
		                         {"type": "button", "index": 5}],
		"jump":                 [{"type": "button", "index": 0}],
		"dash":                 [{"type": "button", "index": 4},
		                         {"type": "button", "index": 1}],
		"move_left":            [{"type": "button", "index": 14},
		                         {"type": "axis", "index": 0, "value": -1.0}],
		"move_right":           [{"type": "button", "index": 15},
		                         {"type": "axis", "index": 0, "value": 1.0}],
		"move_up":              [{"type": "button", "index": 12},
		                         {"type": "axis", "index": 1, "value": -1.0}],
		"move_down":            [{"type": "button", "index": 13},
		                         {"type": "axis", "index": 1, "value": 1.0}],
		"analog_left":          [{"type": "axis", "index": 3, "value": -1.0}],
		"analog_right":         [{"type": "axis", "index": 3, "value": 1.0}],
		"analog_up":            [{"type": "axis", "index": 4, "value": -1.0}],
		"analog_down":          [{"type": "axis", "index": 4, "value": 1.0}],
		"reset_weapon":         [{"type": "button", "index": 10}],
		"select_special":       [{"type": "button", "index": 9}],
		"pause":                [{"type": "button", "index": 6}],
		"ui_accept":            [{"type": "button", "index": 2}],
		"weapon_select_left":   [],
		"weapon_select_right":  [],
	},
}

static func get_profile_names() -> Array:
	return PROFILE_ORDER.duplicate()

static func get_profile_data(profile_name: String) -> Dictionary:
	if profile_name in PROFILES:
		return PROFILES[profile_name]
	return {}

static func make_button_event(button_index: int) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button_index
	ev.device = 0
	return ev

static func make_axis_event(axis: int, axis_value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = axis_value
	ev.device = 0
	return ev

static func event_from_dict(d: Dictionary) -> InputEvent:
	match d.get("type", ""):
		"button":
			return make_button_event(d["index"])
		"axis":
			return make_axis_event(d["index"], d["value"])
	return null
