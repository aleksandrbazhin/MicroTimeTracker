extends VBoxContainer


const USER_SETTINGS_PATH := "user://settings.json"
const NO_TASK_LABEL := "No task"
const MINIMISED_WINDOW_SIZE := Vector2(220, 143)
const TASK_SELECT_WINDOW_SIZE := Vector2(220, 500)
const FILE_DIALOG_WINDOW_SIZE := Vector2(700, 500)

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

onready var minimised_window_position := OS.window_position
onready var hour_label := $MinimizedContainer/VBox/Timer/Hour
onready var minute_label := $MinimizedContainer/VBox/Timer/Minute
onready var second_label := $MinimizedContainer/VBox/Timer/Second
onready var start_button := $MinimizedContainer/VBox/Controls/StartButton
onready var pause_button := $MinimizedContainer/VBox/Controls/PauseButton
onready var complete_button := $MinimizedContainer/VBox/Controls/CompleteButton
onready var task_container := $TasksContainer
onready var task_scroll := $TasksContainer/VBox/ScrollContainer
onready var task_hbox := $TasksContainer/VBox/ScrollContainer/Tasks
onready var active_file_name := $TasksContainer/VBox/CurrentFIle/FileName
onready var active_task_name_label := $MinimizedContainer/VBox/Header/Label

onready var md_file: MdFile = preload("res://MarkdownFile.gd").new()

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
			get_tree().quit()
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
	if active_task_ref != null:
		var task: TaskRow = active_task_ref.get_ref()
		task.set_time_spent(time)


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
	if settings.has("task_container_visible"):
		set_task_container_visible(settings["task_container_visible"], true)


func capture_settings():
	settings["window_position"] = var2str(OS.window_position)
	settings["recent_task"] = active_task_name_label.text
	settings["recent_file"] = active_file_name_path
	settings["task_container_visible"] = task_container.visible


func save_settings():
	capture_settings()
#	print(settings)
	var file := File.new()
	if file.open(USER_SETTINGS_PATH, File.WRITE) != OK:
		return
	file.store_string(JSON.print(settings, "\t"))
	file.close()


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
	get_tree().quit()


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
	OS.set_window_size(TASK_SELECT_WINDOW_SIZE)
	OS.window_position = minimised_window_position


func _on_SelectFileButton_pressed():
	minimised_window_position = OS.window_position
	$FileDialog.popup()
	OS.set_window_size(FILE_DIALOG_WINDOW_SIZE)


func set_task_container_visible(is_visible: bool, is_restoring: bool = false):
	if is_visible:
		if not is_restoring:
			OS.window_position.y -= task_container.rect_size.y
		$TasksContainer.show()
		OS.set_window_size(TASK_SELECT_WINDOW_SIZE)
	else:
		$TasksContainer.hide()
		OS.set_window_size(MINIMISED_WINDOW_SIZE)
		if not is_restoring:
			OS.window_position.y += task_container.rect_size.y


func _on_TasksButton_pressed():
	set_task_container_visible(not $TasksContainer.visible)
	save_settings()


func _on_MicroTimer_gui_input(event):
	toggle_drag(event)


func _on_TasksContainer_gui_input(event):
	toggle_drag(event)


func _on_VBox_gui_input(event):
	toggle_drag(event)


func set_task_file(path: String):
	active_file_name_path = path
	active_file_name.text = path.get_file()

	for child in task_hbox.get_children():
		task_hbox.remove_child(child)
	all_tasks.clear()
	
	for task_block in md_file.read_task_file(path):
		var header := Label.new()
		header.text = task_block["header"]
		task_hbox.add_child(header)
		for task in task_block["tasks"]:
#			print(task)
			var task_node := create_task_row(task)
			task_hbox.add_child(task_node)
			all_tasks.append(task_node)
	$FileDialog.set_current_path(path)


func create_task_row(task: Dictionary) -> TaskRow:
	var task_node: TaskRow = preload("TaskRow.tscn").instance()
	task_node.from_dict(task)
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
	md_file.update_task_completed(task_node)


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
		displayed_time = 0
		display_time(0)
		return
	task.set_active(true)

	active_task_ref = weakref(task)
	start_time  = OS.get_ticks_msec() 
	active_task_name_label.text = task.task_name
	accumulated_time = task.time_spent
	display_time(accumulated_time)
	displayed_time = accumulated_time
	yield(VisualServer, "frame_post_draw")
	if task_scroll.scroll_vertical > task.rect_position.y:
		task_scroll.scroll_vertical = task.rect_position.y - 4
	var task_bottom: int = task.rect_position.y + task.rect_size.y + 4
	if task_scroll.scroll_vertical + task_scroll.rect_size.y < task_bottom:
		task_scroll.scroll_vertical = task_bottom - task_scroll.rect_size.y


func _on_CompleteButton_pressed():
#	is_running = false
#	pause_button.disabled = true
#	complete_button.disabled = true
	if active_task_ref != null:
		var task_node: TaskRow = active_task_ref.get_ref()
		task_node.set_completed(true)
		select_next_available_task(task_node)
	else:
		start_button.disabled = false
		is_running = false
		pause_button.disabled = true
		complete_button.disabled = true
		displayed_time = 0
		display_time(0)


func _on_FileDialog_file_selected(path: String):
	set_task_file(path)
	if not all_tasks.empty():
		select_next_available_task(all_tasks.front())
	else:
		set_active_task(null)
	save_settings()


func _exit_tree():
	save_settings()
