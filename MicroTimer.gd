extends VBoxContainer


const USER_SETTINGS_PATH := "user://settings.json"
const NO_TASK_LABEL := "No task"
const FILE_DIALOG_WINDOW_SIZE := Vector2(800, 600)
const TASK_SELECT_WINDOW_SIZE := Vector2(220, 500)

var start_time: int
var displayed_time: int
var pause_start_time: int = 0
var is_running := false
var is_dragging := false
var drag_start_position: Vector2
var settings: Dictionary

# to restore after
onready var minimised_window_size := OS.window_size
onready var minimised_window_position := OS.window_position

onready var hour_label := $MinimizedContainer/VBox/Timer/Hour
onready var minute_label := $MinimizedContainer/VBox/Timer/Minute
onready var second_label := $MinimizedContainer/VBox/Timer/Second
onready var start_button := $MinimizedContainer/VBox/Controls/StartButton
onready var pause_button := $MinimizedContainer/VBox/Controls/PauseButton
onready var complete_button := $MinimizedContainer/VBox/Controls/CompleteButton


func _ready():
	get_tree().get_root().set_transparent_background(true)
	OS.set_window_always_on_top(true)
	start_time = OS.get_ticks_msec()
	displayed_time = 0
	load_settings()


# Fix for window drag (the proper way, I guess, would require fractional window and cursor positioning)
func drag_window(drag_delta: Vector2):
	if abs(drag_delta.x) <= 1:
		drag_delta.x = 0
	if abs(drag_delta.y) <= 1:
		drag_delta.y = 0
	if (drag_delta.abs() > Vector2.ZERO):
		OS.window_position += drag_delta


func _process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		exit()
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and is_dragging:
		drag_window(get_global_mouse_position() - drag_start_position)
	if is_running:
		var elapsed_time = OS.get_ticks_msec() - start_time
		if elapsed_time - displayed_time > 1000:
			display_time(elapsed_time)
			displayed_time = elapsed_time


func display_time(time: int):
	var seconds := time / 1000
	second_label.text = "%02d" % (seconds % 60)
	var minutes := seconds / 60
	minute_label.text = "%02d" % (minutes % 60)
	hour_label.text = "%02d" % (minutes / 60)


func exit():
	get_tree().quit()
	save_settings()


func load_settings():
	var file := File.new()
	if file.open(USER_SETTINGS_PATH, File.READ) != OK:
		return
	var file_text := file.get_as_text()
	file.close()
	var parsed_data = parse_json(file_text)
	if typeof(parsed_data) != TYPE_DICTIONARY:
		return
	settings = parsed_data
	apply_settings()


func apply_settings():
	if settings.has("window_position"):
		OS.window_position = str2var(settings["window_position"])


func save_settings():
	capture_settings()
	var file := File.new()
	if file.open(USER_SETTINGS_PATH, File.WRITE) != OK:
		return
	file.store_string(JSON.print(settings, "\t"))
	file.close()


func capture_settings():
	settings["window_position"] = var2str(OS.window_position)


func start_drag(mouse_position: Vector2):
	drag_start_position = mouse_position
	is_dragging = true


func end_drag():
	is_dragging = false
	save_settings()


func _on_MicroTimer_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if not event.pressed and is_dragging:
			end_drag()
		else:
			start_drag(event.global_position)


func _on_CloseButton_pressed():
	exit()


func _on_StartButton_pressed():
	is_running = true
	
#	displayed_time = 0
#	display_time(0)
	pause_button.disabled = false
	complete_button.disabled = false
	start_button.disabled = true
	if pause_start_time == 0:
		start_time = OS.get_ticks_msec()
	else:
		start_time += OS.get_ticks_msec() - pause_start_time
		pause_start_time = 0


func _on_PauseButton_pressed():
	pause_start_time = OS.get_ticks_msec()
	is_running = false
	pause_button.disabled = true
	start_button.disabled = false


func _on_CompleteButton_pressed():
	displayed_time = 0
	display_time(0)
	is_running = false
	pause_button.disabled = true
	complete_button.disabled = true
	start_button.disabled = false


func _on_FileDialog_hide():
	OS.set_window_size(minimised_window_size)
	OS.window_position = minimised_window_position


func _on_SelectFileButton_pressed():
	minimised_window_size = OS.window_size
	minimised_window_position = OS.window_position
	$FileDialog.show()
	OS.set_window_size(FILE_DIALOG_WINDOW_SIZE)


func _on_TasksButton_pressed():
	if not $TasksContainer.visible:
		minimised_window_size = OS.window_size
		minimised_window_position = OS.window_position
#		$TasksContainer.call_deferred("set_visible", true)
		$TasksContainer.show()
#		OS.set_window_size(TASK_SELECT_WINDOW_SIZE)
		OS.call_deferred("set_window_size", TASK_SELECT_WINDOW_SIZE)
#		$TasksContainer.show()
	else:
		OS.set_window_size(minimised_window_size)
		OS.window_position = minimised_window_position
		$TasksContainer.call_deferred("set_visible", false)
#		$TasksContainer.hide()
	
