extends HBoxContainer

const USER_SETTINGS_PATH = "user://settings.json"


var start_time: int
var displayed_time: int
var is_running := false
var is_dragging := false
var drag_start_position: Vector2
var settings: Dictionary

onready var hour_label := $Container/Timer/Hour
onready var minute_label := $Container/Timer/Minute
onready var second_label := $Container/Timer/Second
onready var stop_button := $Container/Controls/StopButton


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


func _on_CloseButton_pressed():
	exit()


func _on_StartButton_pressed():
	is_running = true
	start_time = OS.get_ticks_msec()
	displayed_time = 0
	display_time(0)
	stop_button.disabled = false


func _on_StopButton_pressed():
	is_running = false
	stop_button.disabled = true


func _on_MicroTimer_gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if not event.pressed and is_dragging:
			end_drag()
		else:
			start_drag(event.global_position)
