extends HBoxContainer

class_name TaskRow


signal checked(is_checked)
signal selected()

var is_completed: bool = false
var time_spent: int = 0
var task_name: String = ""


func set_completed(new_is_completed: bool):
	$CheckBox.pressed = new_is_completed


func set_time_spent(time: int):
	pass


func set_name(new_name: String):
	$Name.text = new_name


func _on_CheckBox_toggled(button_pressed):
	emit_signal("checked", button_pressed)


func _on_Name_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		emit_signal("selected")


func _on_CheckBox_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		emit_signal("selected")
