extends Control

func _ready():
	Games.connect("set_show_ready_toggle_button", self, "_on_set_show_ready_toggle_button")

func _on_set_show_ready_toggle_button(show_value: bool) -> void:
	match show_value:
		true:
			$ReadyToggleButton.show()
		false:
			$ReadyToggleButton.hide()


func _on_ReadyToggleButton_pressed():
	Games.player_ready_toggle()
	$ReadyToggleButton.hide()
