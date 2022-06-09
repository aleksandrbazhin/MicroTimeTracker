# "Micro" time tracker

(It's not micro, because there is no sane options for now to minimize Godot builds adequately.)

## Embedded task tracking

Why not track all the tasks side by side with the source code? No cloud providers, just you and a couple of Markdown files. 

Need synchronization? - Use git

Need time tracker? - Well, here it is. 

The "Micro" time tracker parses tasks in your markdown files, recognizing a tiny subset of Markdown.

## Markdown subset syntax

The following is recognized in a markdown task file. 
```
\n# - task group
\n[] - uncompleted task
\n[x] - completed task
**(hours:minutes:seconds)**\n - time spend on the task

```
 Everything else you can use to format the files as you want. Such time tracking is not enforcing anything. You obviously can edit it anytime you want.

 ## Sync

It's supposed to be synced by git along with the main project, so every member should better use different file with tasks, just to avoid merge conflicts.

Pros: you don't lose your task history. You don't leave ide to check tasks.

Cons: individual contributions are neither measured, nor time spent on one task by different members is added. Add it yourself while resolving merge conflicts, I guess.