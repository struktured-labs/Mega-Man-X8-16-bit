extends X8OptionButton

func setup() -> void:
	set_subweapon_disable(get_subweapon_disable())

func increase_value() -> void:
	set_subweapon_disable(!get_subweapon_disable())

func decrease_value() -> void:
	set_subweapon_disable(!get_subweapon_disable())

func set_subweapon_disable(value: bool) -> void:
	Configurations.set("DisableSubweapons", value)
	display_subweapon()

func get_subweapon_disable():
	if Configurations.exists("DisableSubweapons"):
		return Configurations.get("DisableSubweapons")
	return false

func display_subweapon():
	if Configurations.get("DisableSubweapons"):
		display_value("ON_VALUE")
	else:
		display_value("OFF_VALUE")
