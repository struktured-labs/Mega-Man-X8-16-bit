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
}

const JOY_AXIS_SHORT := {
	"Left Stick X": "LX",
	"Left Stick Y": "LY",
	"Right Stick X": "RX",
	"Right Stick Y": "RY",
	"Left Trigger": "LT",
	"Right Trigger": "RT",
}

static func short_joy_btn(full_name: String) -> String:
	if full_name in JOY_BTN_SHORT:
		return JOY_BTN_SHORT[full_name]
	return full_name

static func short_joy_axis(full_name: String) -> String:
	if full_name in JOY_AXIS_SHORT:
		return JOY_AXIS_SHORT[full_name]
	return full_name

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
	var named_keyboard := false
	var joypad_count := 0
	for button in inputs:
		if (button is InputEventJoypadButton or button is InputEventJoypadMotion) and joypad_count < 2:
			var target = joypad if joypad_count == 0 else joypad2
			if button is InputEventJoypadButton:
				target.set_text(short_joy_btn(Input.get_joy_button_string(button.button_index)))
			elif button is InputEventJoypadMotion:
				target.set_text(short_joy_axis(Input.get_joy_axis_string(button.axis)))
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
