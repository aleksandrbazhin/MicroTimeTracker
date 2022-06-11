# "Micro" time tracker

(It's not micro, because there is no sane options for now to minimize Godot builds adequately.)

## Embedded task tracking

Why not track all the tasks side by side with the source code? No cloud providers, just you and a couple of Markdown files. 

Need synchronization? - Use git.

Need time tracker? - Well, here it is. 

The "Micro" time tracker parses tasks in your markdown files, recognizing a tiny subset of Markdown. It appends time spent on each task into those same tiles.

## Markdown subset syntax

The following is recognized in a Markdown task file. Tasks are from github format.
```
"\n# "     - task block (instead of \n there can be file start). 
             All the tasks should ne in one of the task blocks.
"\n- [ ] " - uncompleted task
"\n- [x] " - completed task
**(int:int:int)**\n - time spend on the task

```
 Everything else you can use to format the files as you want. Such time tracking is not enforcing anything. You obviously can edit it anytime you want.

 ## Sync

It's supposed to be synced by git along with the main project, so every member should better use different file with tasks, just to avoid merge conflicts. If you trust your cloud provider, like Google Disk or Dropbox, you can sync with it.

Pros: 
- You don't leave ide to check tasks. (Don's get distracted by web interfaces)
- You don't lose your task history. 
- You can synchronize task statuses with Git along with your commits.


Cons: 
- Individual contributions are neither measured, nor time spent on one task by different members is added. You have to add it yourself while resolving merge conflicts, I guess.

#### Tips:
1. You can edit all markdown files with VSCode for example, there are some nice extensions for the github format previews (those checklists).

    - Markdown Preview Enhanced
    - GitHub Markdown Preview
    - Markdown Preview Github Styling
2. You can use folders with files task lists as canban boards. When all task in the file are done, move it to another folder, something like that, I guess.