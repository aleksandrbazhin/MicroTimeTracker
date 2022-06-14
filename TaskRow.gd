extends VBoxContainer

class_name TaskRow


signal checked()
signal selected()

var is_completed: bool = false
var time_spent: int = 0
var task_name: String = ""
var file_check_position: int
var file_time_position_start: int
var file_time_position_end: int


func convert_time(time_msec: int) -> String:
	var seconds := time_msec / 1000
	var minutes := seconds / 60
	var time_text := "%02d:%02d" % [minutes / 60, minutes % 60]
	time_text += ":%02d" % (seconds % 60)
	return time_text


func set_completed(new_is_completed: bool):
	is_completed = new_is_completed
	$HBox/Name.disabled = is_completed
	$HBox/CheckBox.pressed = is_completed


func set_time_spent(new_time: int):
	$HBox/Time.text = convert_time(new_time)
	time_spent = new_time


func set_name(new_name: String):
	task_name = new_name
	$HBox/Name.text = new_name
	$FullText/Label.text = new_name


func _on_CheckBox_toggled(button_pressed):
	set_completed(button_pressed)
	emit_signal("checked")


func _on_Name_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if not $HBox/Name.disabled:
			emit_signal("selected")


func _on_CheckBox_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		pass


func set_active(is_active: bool):
	$HBox/Control/ColorRect.visible = is_active
	$FullText.visible = is_active


func from_dict(task_dict: Dictionary):
	set_name(task_dict["name"])
	set_completed(task_dict["completed"])
	set_time_spent(task_dict["time_spent"])
	file_check_position = task_dict["file_check_position"]
	file_time_position_start = task_dict["file_time_position_start"]
	file_time_position_end = task_dict["file_time_position_end"]
#	print(task_name, " ", file_time_position_start, " ", file_time_position_end)


func move_string_position(delta: int):
	file_check_position += delta
	file_time_position_start += delta
	file_time_position_end += delta
