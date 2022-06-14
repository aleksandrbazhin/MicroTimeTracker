extends HBoxContainer


const USER_SETTINGS_PATH := "user://settings.json"
#const MD_FILE_SAVE_INTERVAL_MS := 10000
const NO_TASK_LABEL := "No task"
const MINIMISED_WINDOW_SIZE := Vector2(220, 145)
const TASK_SELECT_WINDOW_SIZE := Vector2(220, 500)
const FILE_DIALOG_WINDOW_SIZE := Vector2(700, 500)
const TASK_CONTAINER_HEIGHT := 351 # dirty fix to not wait whilw the VisualServer recalculates it

var start_time: int = 0 # ticks from program start to pressed start button
var displayed_time: int = 0 # time UI was when last updated
var pause_start_time: int = 0 # ticks from program start to pressed pause button
var accumulated_time: int = 0 # time spent on current task when it is loaded
var is_running := false
var is_dragging := false
var drag_start_position: Vector2
var settings: Dictionary
var active_file_path: String
var all_tasks := []
var active_task_ref: WeakRef = null

onready var minimised_window_position := OS.window_position
onready var hour_label := $Content/VBox/Timer/Hour
onready var minute_label := $Content/VBox/Timer/Minute
onready var second_label := $Content/VBox/Timer/Second
onready var start_button := $Content/VBox/Controls/StartButton
onready var pause_button := $Content/VBox/Controls/PauseButton
onready var complete_button := $Content/VBox/Controls/CompleteButton
onready var task_container := $Content/TasksContainer
onready var task_scroll := $Content/TasksContainer/VBox/ScrollContainer
onready var task_hbox := $Content/TasksContainer/VBox/ScrollContainer/Tasks
onready var active_file_name := $Content/TasksContainer/VBox/CurrentFIle/FileName
onready var active_task_name_label := $Content/VBox/Header/Label
onready var desync_warning := $Content/TasksContainer/VBox/ColorRect
onready var desync_warning_minimized := $Content/VBox/Header/TextureRect
onready var reload_file_button := $Content/TasksContainer/VBox/CurrentFIle/ReloadFile

onready var md_file: MdFile = preload("res://MarkdownFile.gd").new()


func _ready():
	get_tree().get_root().set_transparent_background(true)
	OS.set_window_always_on_top(true)
	start_time = OS.get_ticks_msec()
	displayed_time = 0
	load_settings()
	md_file.connect("desync", self, "show_desync_warning")


func show_desync_warning():
	desync_warning.show()
	desync_warning_minimized.show()


func hide_desync_warning():
	desync_warning.hide()
	desync_warning_minimized.hide()


func _process(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		if $FileDialog.visible:
			$FileDialog.hide()
		else:
			get_tree().quit()
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and is_dragging:
		drag_window(get_global_mouse_position() - drag_start_position)
	if is_running:
		var elapsed_time := OS.get_ticks_msec() - start_time
		elapsed_time += accumulated_time
		if elapsed_time - displayed_time > 1000:
			display_time(elapsed_time)
			displayed_time = elapsed_time
			if active_task_ref != null:
				var task: TaskRow = active_task_ref.get_ref()
				var time_string_length_delta := md_file.update_task_time(task)
				var task_index := all_tasks.find(task)
				if time_string_length_delta > 0 and task_index != -1:
					for i in range(task_index + 1, all_tasks.size()):
						all_tasks[i].move_string_position(time_string_length_delta)


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
		active_task_name_label.text = NO_TASK_LABEL
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
		move_window_to(str2var(settings["window_position"]))
	if settings.has("recent_file"):
		set_task_file(settings["recent_file"])
		if settings.has("recent_task"):
			set_active_task_by_name(settings["recent_task"])
	if settings.has("task_container_visible"):
		set_task_container_visible(settings["task_container_visible"], true)


func capture_settings():
	settings["window_position"] = var2str(OS.window_position)
	settings["recent_task"] = active_task_name_label.text
	settings["recent_file"] = active_file_path
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


func move_window_to(new_position: Vector2):
	var screen_size := OS.get_screen_size()
	new_position.x = clamp(new_position.x, 0, screen_size.x - OS.window_size.x)
	new_position.y = clamp(new_position.y, 0, screen_size.y - OS.window_size.y)
	OS.window_position = new_position


# Fix for window drag (the proper way, I guess, would require fractional window and cursor positioning)
func drag_window(drag_delta: Vector2):
	if abs(drag_delta.x) <= 1:
		drag_delta.x = 0
	if abs(drag_delta.y) <= 1:
		drag_delta.y = 0
	if (drag_delta.abs() > Vector2.ZERO):
		move_window_to(OS.window_position + drag_delta)


func _on_CloseButton_pressed():
	get_tree().quit()


func _on_StartButton_pressed():
	is_running = true
	pause_button.disabled = false
	complete_button.disabled = false
	start_button.disabled = true
	
	if pause_start_time != 0:
		var pause_duration := OS.get_ticks_msec() - pause_start_time
		start_time += pause_duration
		pause_start_time = 0
	else:
		start_time = OS.get_ticks_msec()


func _on_PauseButton_pressed():
	pause_start_time = OS.get_ticks_msec()
	is_running = false
	pause_button.disabled = true
	start_button.disabled = false


func _on_FileDialog_hide():
	OS.set_window_size(TASK_SELECT_WINDOW_SIZE)
	move_window_to(minimised_window_position)


func _on_SelectFileButton_pressed():
	minimised_window_position = OS.window_position
	$FileDialog.popup()
	OS.set_window_size(FILE_DIALOG_WINDOW_SIZE)
	move_window_to(minimised_window_position)


func set_task_container_visible(is_setting_visible: bool, is_restoring: bool = false):
	if is_setting_visible:
		$Content/VBox/Header/TasksButton.flip_v = true
		task_container.modulate = Color(0, 0, 0, 0)
		task_container.show()
		yield(VisualServer,"frame_post_draw")
		if not is_restoring:
			move_window_to(OS.window_position - Vector2(0, TASK_CONTAINER_HEIGHT))
		task_container.modulate = Color(1, 1, 1, 1)
		OS.set_window_size(TASK_SELECT_WINDOW_SIZE)
	else:
		$Content/VBox/Header/TasksButton.flip_v = false
		task_container.modulate = Color(0, 0, 0, 0)
		yield(VisualServer,"frame_post_draw")
		OS.set_window_size(MINIMISED_WINDOW_SIZE)
		if not is_restoring:
			move_window_to(OS.window_position + Vector2(0, TASK_CONTAINER_HEIGHT))
		task_container.hide()


func _on_TasksButton_pressed():
	set_task_container_visible(not task_container.visible)
	if active_task_ref != null:
		scroll_to_active_task(active_task_ref.get_ref())
	save_settings()


func _on_MicroTimer_gui_input(event):
	toggle_drag(event)


func _on_TasksContainer_gui_input(event):
	toggle_drag(event)


func _on_VBox_gui_input(event):
	toggle_drag(event)


func load_tasks_from_file(path: String):
	hide_desync_warning()
	for child in task_hbox.get_children():
		task_hbox.remove_child(child)
	all_tasks.clear()
	for task_block in md_file.read_task_file(path):
		var header := Label.new()
		header.clip_text = true
		header.text = task_block["header"]
		task_hbox.add_child(header)
		for task in task_block["tasks"]:
			var task_node := create_task_row(task)
			task_hbox.add_child(task_node)
			all_tasks.append(task_node)


func set_task_file(path: String):
	active_file_path = path
	active_file_name.text = active_file_path.get_file()
	$FileDialog.set_current_path(active_file_path)
	load_tasks_from_file(active_file_path)
	reload_file_button.disabled = false


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


func set_active_task_by_name(task_name: String):
	for task in all_tasks:
		if task.task_name == task_name:
			set_active_task(task)
			return
	if not all_tasks.empty():
		select_next_available_task(all_tasks.front())
		return
	set_active_task(null)


func set_active_task(task_node: TaskRow):
	start_button.disabled = false
	is_running = false
	pause_button.disabled = true
	for t in all_tasks:
		t.set_active(false)
	if task_node == null:
#		complete_button.disabled = true
		active_task_ref = null
		active_task_name_label.text = NO_TASK_LABEL
		accumulated_time = 0
		displayed_time = 0
		display_time(0)
		return
	task_node.set_active(true)
	active_task_ref = weakref(task_node)
	start_time  = OS.get_ticks_msec() 
	active_task_name_label.text = task_node.task_name
	accumulated_time = task_node.time_spent
	pause_start_time = 0
	display_time(accumulated_time)
	displayed_time = accumulated_time
	yield(VisualServer, "frame_post_draw")
	scroll_to_active_task(task_node)


func scroll_to_active_task(task_node: TaskRow):
	if task_scroll.scroll_vertical > task_node.rect_position.y:
		task_scroll.scroll_vertical = task_node.rect_position.y - 4
	var task_bottom: int = int(task_node.rect_position.y + task_node.rect_size.y) + 4
	if task_scroll.scroll_vertical + task_scroll.rect_size.y < task_bottom:
		task_scroll.scroll_vertical = task_bottom - task_scroll.rect_size.y


func _on_CompleteButton_pressed():
	if active_task_ref != null:
		var task_node: TaskRow = active_task_ref.get_ref()
		task_node.set_completed(true)
		select_next_available_task(task_node)
	else:
		set_active_task(null)


func _on_FileDialog_file_selected(path: String):
	set_task_file(path)
	if not all_tasks.empty():
		select_next_available_task(all_tasks.front())
	else:
		set_active_task(null)
	save_settings()


func _exit_tree():
	save_settings()


func _on_ReloadFile_pressed():
	load_tasks_from_file(active_file_path)
	set_active_task_by_name(active_task_name_label.text)
