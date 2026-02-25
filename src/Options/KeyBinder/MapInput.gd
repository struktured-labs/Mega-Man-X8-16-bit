extends X8TextureButton

var waiting_for_input = false
var original_event : InputEvent
var timer := 0.0
var old_text := ""
signal waiting
signal updated_event
onready var text: Label = $text
onready var actionname: Label = $"../actionname"

var doubled_input

func _ready() -> void:
	InputManager.connect("double_check",self,"check_for_doubles")
	InputManager.connect("double_detected",self,"double_warning")

func check_for_doubles(new_button_text, _action_display, _action_key):
	if new_button_text in ["", "(not set)", "..."]:
		return
	var my_text = get_text()
	if my_text in ["", "(not set)", "..."]:
		return
	var my_action = get_parent().action
	if my_text == new_button_text and my_action != _action_key:
		if InputManager.actions_can_conflict(my_action, _action_key):
			flash_conflict()
			InputManager.emit_signal("double_detected", new_button_text, actionname.text, my_action)

func double_warning(double_button_text, _action_display, _action_key):
	var my_text = get_text()
	var my_action = get_parent().action
	if my_text == double_button_text and my_action != _action_key:
		if InputManager.actions_can_conflict(my_action, _action_key):
			flash_conflict()

func flash_conflict() -> void:
	modulate = Color(1.0, 0.3, 0.3, 1.0)
	reset_tween()
	tween.tween_property(self, "modulate", idle_color, 2.0)
	print("Binding conflict: '%s' on %s" % [get_text(), actionname.text])

func _process(delta: float) -> void:
	if timer >= 0.01:
		timer += delta
		text.self_modulate.a = inverse_lerp(-1,1,sin(timer * 6))
	if timer > 5:
		print_debug("waiting cancel")
		menu.emit_signal("unlock_buttons")
		grab_focus()
		waiting_for_input = false
		timer = 0
		set_text(old_text)
		text.self_modulate.a = 1.0

func _input(event: InputEvent) -> void:
	if not has_focus():
		return
	if event is InputEventMouseMotion:
		return
	elif timer > 0.25:
		# Clear binding with Delete or Backspace
		if event is InputEventKey and not event.is_pressed():
			if event.scancode == KEY_DELETE or event.scancode == KEY_BACKSPACE:
				clear_current_event()
				return
		if name == "key" and event is InputEventMouseButton and not event.is_pressed():
			set_new_action_event(event)
		elif name == "key" and event is InputEventKey and not event.is_pressed():
			set_new_action_event(event)
		elif name.begins_with("joypad") and event is InputEventJoypadButton and not event.is_pressed():
			set_new_action_event(event)
		elif name.begins_with("joypad") and event is InputEventJoypadMotion:
			if abs(event.axis_value) > 0.35:
				set_new_action_event(event)

func set_new_action_event(event) -> void:
	InputManager.set_new_action_event(get_parent().action,event,original_event)
	emit_signal("updated_event")
	waiting_for_input = false
	timer = 0
	text.self_modulate.a = 1.0
	menu.emit_signal("unlock_buttons")
	grab_focus()

func clear_current_event() -> void:
	if original_event:
		InputManager.clear_action_event(get_parent().action, original_event)
	original_event = null
	emit_signal("updated_event")
	waiting_for_input = false
	timer = 0
	text.self_modulate.a = 1.0
	set_text("(not set)")
	menu.emit_signal("unlock_buttons")
	grab_focus()

func on_press() -> void:
	if timer == 0:
		.on_press()
		#action = $"..".action
		old_text = get_text()
		set_text("...")
		timer = 0.01
		emit_signal("waiting")
		menu.emit_signal("lock_buttons")
		focus_mode = Control.FOCUS_ALL
		grab_focus()

func set_text(txt) -> void:
	InputManager.emit_signal("double_check", txt, $"../actionname".text, get_parent().action)
	text.text = txt

func get_text() -> String:
	 return text.text
