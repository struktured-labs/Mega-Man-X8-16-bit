extends X8OptionButton

const native = Vector2(398, 224)
const w_size := "WindowSize"
var current_multiplier = 3


func setup() -> void:
	var saved = Configurations.get(w_size)
	if saved and saved >= 1 and saved <= 10:
		current_multiplier = saved
		_display_current()
	else:
		display_value(_size_str(OS.get_window_size()))

func increase_value() -> void:
	current_multiplier = (current_multiplier % 10) + 1
	_apply()

func decrease_value() -> void:
	current_multiplier = ((current_multiplier - 2 + 10) % 10) + 1
	_apply()

func _apply() -> void:
	Configurations.set(w_size, current_multiplier)
	_display_current()
	if not Configurations.get("Fullscreen"):
		OS.set_window_size(native * current_multiplier)

func _display_current() -> void:
	display_value(_size_str(native * current_multiplier))

func _size_str(size: Vector2) -> String:
	return str(int(size.x)) + "x" + str(int(size.y))
