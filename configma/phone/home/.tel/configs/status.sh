#!/usr/bin/env bash

############### TEL Status Window Configuration ###########
#       Status scripts located at ~/.tel/status/*         #
#              use tel-restart to see changes             #
###########################################################


export STATUS_WINDOW_ENABLED=false # Enable / Disable Status window completely [true/false]
export STATUS_MANAGER_SLEEP=2 # Time status manager pauses for, before reading new data, lower = more responsive, higher = more battery saved [seconds]
export STATUS_SCRIPTS_SLEEP=8 # Time each status script pauses for before running again, lower = more responsive, higher = more battery saved [seconds]
export STATUS_TIMEOUT=60 # Timeout for any misbehaviour in status scripts [seconds]

