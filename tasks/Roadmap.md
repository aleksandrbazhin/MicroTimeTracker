# Roadmap for MicroTracker


## Known bugs
- [x] This file does not reads properly **(00:01:51)**
- [x] Task after pause is not increasing it's time **(00:36:16)**
- [ ] Start first task from file on startup if file is valid, but task isn't **(00:00:02)**
- [ ] Check overall start/pause/complete behavior


## Improvements (maybe sometime later)

### Minor problems
- [ ] Flickering on task list expand
- [ ] First task list expansion after launch causes window to jump down

### Features
- [ ] Mouseover tooltips (at least full task text) **(00:00:04)**
- [ ] Dark / light theme

### User settings
Implement user setting through some .ini fil
- [x] Timer s ave interval (every second, every minute, etc.) **(00:00:07)**
- [ ] Expand seconds in task list **(00:00:11)**


### Refactoring
- [ ] Move parser script to the node owning all the task.  **(00:00:16)**
This way:
    - No problems with ugly dictionary return
    - Some of the task and file related code may be moved there