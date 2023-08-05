extends LineEdit
signal sendMessage
func _input(event):
	if(has_focus()):
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ENTER:
				sendMessage.emit()
