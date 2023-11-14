#!/usr/bin/env python3

import subprocess
import sys

back = False
if len(sys.argv) > 2:
    print('unknown args')
    exit(1)
elif len(sys.argv) == 2:
    if sys.argv[1] == '-b':
        back = True
    else:
        print('unknown args')
        exit(1)

activities = subprocess.getoutput('kactivities-cli --list-activities')
activities = list(map(lambda x: x.split(), activities.splitlines()))
print(activities)

current = subprocess.getoutput('kactivities-cli --current-activity').split()
print(current)

i = list(map(lambda x: x[1], activities)).index(current[1])
if back:
    j = (i + len(activities) - 1) % len(activities)
else:
    j = (i+1) % len(activities)
next = activities[j]
print(next)

move_focus = subprocess.getoutput(f'kactivities-cli --set-current-activity {next[1]}')
print(move_focus)

