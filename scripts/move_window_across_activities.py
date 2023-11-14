#!/usr/bin/env python3

import subprocess

# - [virtual desktop - Move windows between KDE activties - Super User](https://superuser.com/a/1795736)
# - [in kde how to get the current activity name by command line in konsole? - English / Applications - openSUSE Forums](https://forums.opensuse.org/t/in-kde-how-to-get-the-current-activity-name-by-command-line-in-konsole/106087/4)

activities = subprocess.getoutput('kactivities-cli --list-activities')
activities = list(map(lambda x: x.split(), activities.splitlines()))
print(activities)

current = subprocess.getoutput('kactivities-cli --current-activity').split()
print(current)

i = list(map(lambda x: x[1], activities)).index(current[1])
j = (i+1) % len(activities)
next = activities[j]
print(next)

window_id = subprocess.getoutput('xdotool getwindowfocus')
move = subprocess.getoutput(f'xprop -f _KDE_NET_WM_ACTIVITIES 8s -id {window_id} -set _KDE_NET_WM_ACTIVITIES {next[1]}')
print(move)

move_focus = subprocess.getoutput(f'kactivities-cli --set-current-activity {next[1]}')
print(move_focus)

# focus_window = subprocess.getoutput(f'wmctl -ia {window_id}')
focus_window = subprocess.getoutput(f'xdotool windowactivate {window_id}')
print(focus_window)

'''
activities = subprocess.getoutput('dbus-send --session --dest=org.kde.ActivityManager --type=method_call --print-reply=literal /ActivityManager/Activities "org.kde.ActivityManager.Activities.ListActivitiesWithInformation" | grep int32')
activities = list(map(lambda x: x.split()[:2], activities.splitlines()))
print(activities)

curr = subprocess.getoutput('qdbus org.kde.ActivityManager /ActivityManager/Activities CurrentActivity')
i = list(map(lambda x: x[0], activities)).index(curr)
print(curr, activities[i])
print((i+1) % len(activities), i)

next = activities[(i+1) % len(activities)]
print(next)

move = subprocess.getoutput(f'xprop -f _KDE_NET_WM_ACTIVITIES 8s -id $(xdotool getwindowfocus) -set _KDE_NET_WM_ACTIVITIES {next[0]}')
print(move)

move_focus = subprocess.getoutput(f'kactivities-cli --set-current-activity {next[0]}')
print(move_focus)
'''



