extends HBoxContainer

class_name TaskRow


signal checked()
signal selected()

var is_completed: bool = false
var time_spent: int = 0
var task_name: String = ""


func convert_time(time_msec: int) -> String:
	var seconds := time_msec / 1000
	var minutes := seconds / 60
	var time_text := "%02d" % (minutes / 60) + ":%02d" % (minutes % 60)
	time_text += ":%02d" % (seconds % 60)
	return time_text


func set_completed(new_is_completed: bool):
	is_completed = new_is_completed
	$Name.disabled = is_completed
	$CheckBox.pressed = is_completed


func set_time_spent(new_time: int):
	$Time.text = convert_time(new_time)
	time_spent = new_time


func set_name(new_name: String):
	task_name = new_name
	$Name.text = new_name


func _on_CheckBox_toggled(button_pressed):
	set_completed(button_pressed)
	emit_signal("checked")


func _on_Name_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if not $Name.disabled:
			emit_signal("selected")


func _on_CheckBox_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		pass


func set_active(is_active: bool):
	$Control/ColorRect.visible = is_active
