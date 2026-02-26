extends LightGroup

onready var action_name: Label = $actionname
onready var key: = $key
onready var joypad := $joypad
onready var joypad2 := $joypad2
var action

const JOY_BTN_SHORT := {
	"Face Button Bottom": "A",
	"Face Button Right": "B",
	"Face Button Left": "X",
	"Face Button Top": "Y",
	"Left Shoulder": "LB",
	"Right Shoulder": "RB",
	"Left Trigger": "LT",
	"Right Trigger": "RT",
	"Left Stick": "L3",
	"Right Stick": "R3",
	"DPAD Up": "D-Up",
	"DPAD Down": "D-Dn",
	"DPAD Left": "D-L",
	"DPAD Right": "D-R",
	"L": "LB",
	"L2": "LT",
	"L3": "L3",
	"R": "RB",
	"R2": "RT",
	"R3": "R3",
	"Select": "Back",
	"Start": "Start",
	"Guide": "Guide",
}

# Axis direction suffixes: axis_name -> [negative_suffix, positive_suffix]
const AXIS_DIRS := {
	"LX": ["L", "R"],
	"LY": ["U", "D"],
	"RX": ["L", "R"],
	"RY": ["U", "D"],
}

const JOY_AXIS_SHORT := {
	"Left Stick X": "LX",
	"Left Stick Y": "LY",
	"Right Stick X": "RX",
	"Right Stick Y": "RY",
	"Left Trigger": "LT",
	"Right Trigger": "RT",
}

# Direct axis index → short name (for controllers where Input.get_joy_axis_string() returns "")
const AXIS_INDEX_NAMES := {
	0: "LX", 1: "LY", 2: "LT",
	3: "RX", 4: "RY", 5: "RT",
}

# Raw xpad button index → short name (indices 6-10 differ from Godot's standard SDL mapping)
const BTN_INDEX_NAMES := {
	0: "A", 1: "B", 2: "X", 3: "Y",
	4: "LB", 5: "RB", 6: "Back", 7: "Start",
	8: "Guide", 9: "L3", 10: "R3",
	12: "D-Up", 13: "D-Dn", 14: "D-L", 15: "D-R",
}

static func short_joy_btn(full_name: String, button_index: int = -1, joy_known: bool = true) -> String:
	if not joy_known and button_index in BTN_INDEX_NAMES:
		return BTN_INDEX_NAMES[button_index]
	if full_name in JOY_BTN_SHORT:
		return JOY_BTN_SHORT[full_name]
	if full_name != "":
		return full_name
	if button_index in BTN_INDEX_NAMES:
		return BTN_INDEX_NAMES[button_index]
	if button_index >= 0:
		return "Btn%d" % button_index
	return "???"

static func short_joy_axis(full_name: String, axis: int = -1, axis_value: float = 0.0, joy_known: bool = true) -> String:
	var base_name: String
	# For unmapped controllers, always use raw index table (Godot returns wrong names)
	if not joy_known and axis in AXIS_INDEX_NAMES:
		base_name = AXIS_INDEX_NAMES[axis]
	elif full_name in JOY_AXIS_SHORT:
		base_name = JOY_AXIS_SHORT[full_name]
	elif full_name != "":
		base_name = full_name
	elif axis in AXIS_INDEX_NAMES:
		base_name = AXIS_INDEX_NAMES[axis]
	elif axis >= 0:
		base_name = "Ax%d" % axis
	else:
		return "???"
	# Append direction for stick axes
	if base_name in AXIS_DIRS and axis_value != 0.0:
		var dir = AXIS_DIRS[base_name][0] if axis_value < 0 else AXIS_DIRS[base_name][1]
		return base_name + " " + dir
	return base_name

func setup(_action, readname, menu) -> void:
	key.connect_lock_signals(menu)
	joypad.connect_lock_signals(menu)
	joypad2.connect_lock_signals(menu)
	action = _action
	action_name.text = tr(readname)
	var _s = key.connect("updated_event",self,"get_inputs_and_set_names")
	_s = joypad.connect("updated_event",self,"get_inputs_and_set_names")
	_s = joypad2.connect("updated_event",self,"get_inputs_and_set_names")
	get_inputs_and_set_names(action)

func get_inputs_and_set_names(_action = action) -> void:
	var inputs = InputMap.get_action_list(_action)
	var joy_known := Input.is_joy_known(0)
	var named_keyboard := false
	var joypad_count := 0
	for button in inputs:
		if (button is InputEventJoypadButton or button is InputEventJoypadMotion) and joypad_count < 2:
			var target = joypad if joypad_count == 0 else joypad2
			if button is InputEventJoypadButton:
				target.set_text(short_joy_btn(Input.get_joy_button_string(button.button_index), button.button_index, joy_known))
			elif button is InputEventJoypadMotion:
				target.set_text(short_joy_axis(Input.get_joy_axis_string(button.axis), button.axis, button.axis_value, joy_known))
			target.original_event = button
			joypad_count += 1
		elif (button is InputEventKey) and not named_keyboard:
			key.set_text(button.as_text())
			key.original_event = button
			named_keyboard = true
		elif (button is InputEventMouseButton) and not named_keyboard:
			key.set_text("Mouse" + str(button.button_index))
			key.original_event = button
			named_keyboard = true
	# Clear unset slots
	if joypad_count < 2:
		joypad2.set_text("(not set)")
		joypad2.original_event = null
	if joypad_count == 0:
		joypad.set_text("(not set)")
		joypad.original_event = null
