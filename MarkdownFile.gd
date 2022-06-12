extends Object

class_name MdFile

signal desync()

# it's a list of task blocks, each looks like this 
# { "header": String,
#	"tasks": [ 
#			{
#				"name": String, 
#				"time_spent": int (msecs),
#				"completed": bool,
#				"file_check_position": global position in the file string of this task checkbox
#				"file_time_position_start": global position in the file string of this task time
#				"file_time_position_end": global position in the file string of this task time ends
#			}
#		]
# }
var data := []
var current_path := ""
var current_file_text := ""
var current_hash := 0


func read_task_file(path: String) -> Array:
	var file := File.new()
	if file.open(path, File.READ) != OK:
		return []
	current_path = path
	current_file_text = file.get_as_text()
	current_hash = hash(current_file_text)
	file.close()
	return parse(current_file_text)


func update_task_completed(task: TaskRow):
	print("updating")
	if not check_desync():
		print("desync")
		emit_signal("desync")
		return
	current_file_text.erase(task.file_check_position, 1)
	var check_mark :=  "x" if task.is_completed else " "
	current_file_text = current_file_text.insert(task.file_check_position, check_mark)
	current_hash = hash(current_file_text)
	write_task_file(current_file_text)



func check_desync() -> bool:
	var file := File.new()
	if file.open(current_path, File.READ) != OK:
		return false
	var file_text := file.get_as_text()
	print(hash(file_text), " ", current_hash)
	if hash(file_text) == current_hash:
		return true
	return false


func write_task_file(text: String):
#	print("\n\nStoring\n", text)
	var file := File.new()
	if file.open(current_path, File.WRITE) != OK:
		return 
	file.store_string(text)
	file.close()


func parse(text: String) -> Array:
	var task_blocks := []
	
	var section_regex := RegEx.new()
	section_regex.compile('# (.+)[\r\n]+- \\[[ x]\\][^#]*')
	var task_regex := RegEx.new()
	task_regex.compile('\n- \\[( |x)\\] (.*)')
	var time_regex := RegEx.new()
	time_regex.compile('(?:\\*\\*\\(\\d{2,}\\:\\d{2}:\\d{2}\\)\\*\\*)')
	
	for section_result in section_regex.search_all(text):
		var section = section_result.strings[0]
		var first_line_break: int = section.find("\n")
		if first_line_break == -1:
			first_line_break = section.length() - 1
		var block := {
			"header": section_result.strings[1],
			"tasks": []
		}
		var section_offset: int = section_result.get_start()
		for task_result in task_regex.search_all(section):
			var task := {
					"name": task_result.strings[2], 
					"time_spent": 0,
					"completed": true if task_result.strings[1] == "x" else false,
					"file_check_position": section_offset + task_result.get_start() + 4,
					"file_time_position_start": section_offset + task_result.get_end(),
					"file_time_position_end": section_offset + task_result.get_end(),
				}
			var time_result: RegExMatch = time_regex.search(task["name"])
			if time_result != null:
				var time_string = time_result.strings[0]
				task["time_spent"] = time_from_text(time_string)
				task["name"] = task["name"].replace(time_string, "")
				task["file_time_position_start"] = section_offset + task["file_check_position"] + 2 + time_result.get_start()
				task["file_time_position_end"] = section_offset + task["file_check_position"] + 2 + time_result.get_end()
			block["tasks"].append(task)
		task_blocks.append(block)
	return task_blocks


func time_from_text(time_string: String) -> int:
	if time_string.empty():
		return 0
	return 50000000
