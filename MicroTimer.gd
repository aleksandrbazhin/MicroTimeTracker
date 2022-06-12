extends VBoxContainer


const USER_SETTINGS_PATH := "user://settings.json"
const NO_TASK_LABEL := "No task"
const FILE_DIALOG_WINDOW_SIZE := Vector2(700, 500)
const TASK_SELECT_WINDOW_SIZE := Vector2(220, 500)

var start_time: int
var displayed_time: int
var pause_start_time: int = 0
var accumulated_time: int = 0
var is_running := false
var is_dragging := false
var drag_start_position: Vector2
var settings: Dictionary
var active_file_name_path: String
var all_tasks := []
var active_task_ref: WeakRef = null

# to restore after expanding task list
onready var minimised_window_size := OS.window_size
onready var minimised_window_position := OS.window_position

onready var hour_label := $MinimizedContainer/VBox/Timer/Hour
onready var minute_label := $MinimizedContainer/VBox/Timer/Minute
onready var second_label := $MinimizedContainer/VBox/Timer/Second
onready var start_button := $MinimizedContainer/VBox/Controls/StartButton
onready var pause_button := $MinimizedContainer/VBox/Controls/PauseButton
onready var complete_button := $MinimizedContainer/VBox/Controls/CompleteButton
onready var task_scroll := $TasksContainer/VBox/ScrollContainer
onready var task_container := $TasksContainer/VBox/ScrollContainer/Tasks
onready var active_file_name := $TasksContainer/VBox/CurrentFIle/FileName
onready var active_task_name_label := $MinimizedContainer/VBox/Header/Label

onready var md_parser: MdParser = preload("res://Parser.gd").new()

func _ready():
	get_tree().get_root().set_transparent_background(true)
	OS.set_window_always_on_top(true)
	start_time = OS.get_ticks_msec()
	displayed_time = 0
	load_settings()


func _process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		if $FileDialog.visible:
			$FileDialog.hide()
		else:
			exit()
#	Input.is_mouse_button_pressed(BUTTON_LEFT)
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and is_dragging:
		drag_window(get_global_mouse_position() - drag_start_position)
	if is_running:
		var elapsed_time = accumulated_time + OS.get_ticks_msec() - start_time
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
	if settings.has("recent_file"):
		set_task_file(settings["recent_file"])
		if settings.has("recent_task"):
			set_task_by_name(settings["recent_task"])


func save_settings():
	capture_settings()
	var file := File.new()
	if file.open(USER_SETTINGS_PATH, File.WRITE) != OK:
		return
	file.store_string(JSON.print(settings, "\t"))
	file.close()


func capture_settings():
	settings["window_position"] = var2str(OS.window_position)
	settings["recent_task"] = active_task_name_label.text
	settings["recent_file"] = active_file_name_path


func start_drag(mouse_position: Vector2):
	drag_start_position = mouse_position
	is_dragging = true


func end_drag():
	is_dragging = false
	save_settings()


func toggle_drag(event:InputEventMouseButton):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if not event.pressed and is_dragging:
			end_drag()
		else:
			start_drag(event.global_position)

# Fix for window drag (the proper way, I guess, would require fractional window and cursor positioning)
func drag_window(drag_delta: Vector2):
	if abs(drag_delta.x) <= 1:
		drag_delta.x = 0
	if abs(drag_delta.y) <= 1:
		drag_delta.y = 0
	if (drag_delta.abs() > Vector2.ZERO):
		OS.window_position += drag_delta


func _on_CloseButton_pressed():
	exit()


func _on_StartButton_pressed():
	is_running = true
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
		$TasksContainer.show()
		OS.call_deferred("set_window_size", TASK_SELECT_WINDOW_SIZE)
	else:
		$TasksContainer.hide()
		OS.set_window_size(minimised_window_size)
		OS.window_position = minimised_window_position


func _on_MicroTimer_gui_input(event):
	toggle_drag(event)


func _on_TasksContainer_gui_input(event):
	toggle_drag(event)


func _on_VBox_gui_input(event):
	toggle_drag(event)


#TODO: sabe file hash to be schecked bfore file write
#if hash has changed - do not save the file, show error dialog
func set_task_file(path: String):
	active_file_name_path = path
	active_file_name.text = path.get_file()
	for child in task_container.get_children():
		task_container.remove_child(child)
	all_tasks.clear()
	var file := File.new()
	if file.open(path, File.READ) != OK:
		return
	var file_text := file.get_as_text()
	file.close()
	for task_block in md_parser.parse(file_text):
		var header := Label.new()
		header.text = task_block["header"]
		task_container.add_child(header)
		for task in task_block["tasks"]:
			var task_node := create_task_row(task)
			task_container.add_child(task_node)
			all_tasks.append(task_node)


func create_task_row(task: Dictionary) -> TaskRow:
	var task_node: TaskRow = preload("TaskRow.tscn").instance()
	task_node.set_name(task["name"])
	task_node.set_completed(task["completed"])
	task_node.set_time_spent(task["time_spent"])
	task_node.connect("selected", self, "set_active_task", [task_node])
	task_node.connect("checked", self, "set_task_checked", [task_node])
	return task_node


func select_next_available_task(task_node: TaskRow):
	var task_index := all_tasks.find(task_node)
	if task_index != -1:
		for i in range(all_tasks.size()):
			var next_index := posmod(task_index + i, all_tasks.size())
			if not all_tasks[next_index].is_completed:
				set_active_task(all_tasks[next_index])
				return
	set_active_task(null)


func set_task_checked(task_node: TaskRow):
	if task_node.is_completed:
		select_next_available_task(task_node)


func set_task_by_name(task_name: String):
	for task in all_tasks:
		if task.task_name == task_name:
			set_active_task(task)
			return
	set_active_task(null)


func set_active_task(task: TaskRow):
	for t in all_tasks:
		t.set_active(false)
	if task == null:
		active_task_ref = null
		active_task_name_label.text = NO_TASK_LABEL
		return
	task.set_active(true)
	if task_scroll.scroll_vertical > task.rect_position.y:
		task_scroll.scroll_vertical = task.rect_position.y - 4
	if task_scroll.scroll_vertical + task_scroll.rect_size.y < task.rect_position.y:
		task_scroll.scroll_vertical = task.rect_position.y + task.rect_size.y - task_scroll.rect_size.y + 4
	active_task_ref = weakref(task)
	start_time  = OS.get_ticks_msec() 
	active_task_name_label.text = task.task_name
	save_settings()
	accumulated_time = task.time_spent
	display_time(accumulated_time)
	displayed_time = accumulated_time


func _on_CompleteButton_pressed():
	displayed_time = 0
	display_time(0)
	is_running = false
	pause_button.disabled = true
	complete_button.disabled = true
	start_button.disabled = false
	if active_task_ref != null:
		var task_node: TaskRow = active_task_ref.get_ref()
		task_node.set_completed(true)
		select_next_available_task(task_node)


func _on_FileDialog_file_selected(path: String):
	set_task_file(path)
	if not all_tasks.empty():
		select_next_available_task(all_tasks.front())
	else:
		set_active_task(null)
	save_settings()


