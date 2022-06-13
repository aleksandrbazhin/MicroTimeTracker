# Roadmap for MicroTracker



## Known bugs
- [x] This file does not reads properly **(00:01:51)**
- [ ] Task after pause is not increasing it's time
- [ ] Flickering on task list expand
- [ ] First task list expansion causes window to jump down
- [ ] Start first task from file on startup if file is valid, but task isn't


## Features (maybe sometime later)
- [ ] Mouse over hints (at least full task text) **(00:00:01)**


### User settings
Implement user setting through some .ini fil
- [ ] Timer save interval (every second, every minute, etc.)
- [ ] Expand seconds in task list **(00:00:09)**

### Refactoring
- [ ] Move parser script to the node owning all the task. This way
- No problems with ugly dictionary return
- Some of the task and file related code may be moved there