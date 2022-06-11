extends Object

class_name MdParser


# it's a list of task blocks, each looks like this 
# { "header": String,
#	"tasks": [ 
#			{
#				"name": String, 
#				"time_spent": int (msecs),
#				"completed": bool
#			}
#		]
# }
# For example
#	{"header": "Block1",
#	"tasks": [
#		{
#			"name": "Task one", 
#			"time_spent": 0,
#			"completed": false
#		},
#		{
#			"name": "Task two", 
#			"time_spent": 11000000,
#			"completed": false
#		}
#	]}]
func parse(text: String) -> Array:
	var task_blocks := []
	var sections: PoolStringArray = text.split("\n# ", false, 1)
	if sections.size() == 0:
		return []
	sections[0] = sections[0].lstrip(" \n\r")
	sections[0] = sections[0].trim_prefix("# ")
	var task_regex := RegEx.new()
	task_regex.compile('\n- \\[( |x)\\] (.*)')
	var time_regex := RegEx.new()
	time_regex.compile('(?:\\*\\*\\(\\d{2,}\\:\\d{2}:\\d{2}\\)\\*\\*)')
	for section in sections:
		var first_line_break: int = section.find("\n")
		if first_line_break == -1:
			first_line_break = section.length() - 1
		var block := {
			"header": section.left(first_line_break).lstrip(" \n"),
			"tasks": []
		}
		for task_result in task_regex.search_all(section):
#			print(task_result.strings)
			var task := {
					"name": task_result.strings[2], 
					"time_spent": 0,
					"completed": true if task_result.strings[1] == "x" else false
				}
			var time_result: RegExMatch = time_regex.search(task["name"])
			if time_result != null:
				task["time_spent"] = time_from_text(time_result.strings[0])
			block["tasks"].append(task)
		task_blocks.append(block)
	return task_blocks


func time_from_text(time_string: String) -> int:
	if time_string.empty():
		return 0
	return 50000000
