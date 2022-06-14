# Roadmap for MicroTracker


## Known bugs
- [x] This file does not reads properly **(00:11:51)**
- [x] Task after pause is not increasing it's time **(00:36:16)**
- [x] Start first task from file on startup if file is valid, but task isn't **(00:00:02)**
- [ ] Check overall start/pause/complete behavior **(00:00:02)**
- [ ] On Windows the program window can go out of the screen **(01:00:00)**
- [x] On first start there is junk in the current task **(00:01:00)**
- [x] Disable reload button if no file selected / display "Load file" message **(00:00:05)**

## Improvements (maybe sometime later)

### Minor problems
- [x] Flickering on task list expand **(00:30:00)**
- [x] First task list expansion after launch causes window to jump down **(00:10:00)**
- [ ] Test for multiple monitor behavior and different resolution (currently only tested on 1920x1080)

### Features
- [x] Mouseover tooltips (at least full task text) **(00:02:28)**
- [ ] Dark / light / other themes

### User settings
Implement user setting through some .ini fil
- [ ] Varying time save interval (every second, every minute, etc.) **(00:00:07)**
- [ ] Expand/hide seconds in task list **(00:00:11)**


### Refactoring
- [ ] Move parser script to the node owning all the task.  **(00:00:16)**
This way:
    - No problems with ugly dictionary return
    - Some of the task and file related code may be moved there