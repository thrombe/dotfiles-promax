
path="/sys/class/backlight/nvidia_wmi_ec_backlight/brightness"

dothething() {
  contents="$(cat $path)"
  echo "{\"level\": \"$contents\"}"
}

dothething
inotifywait -q -m -e modify $path |

while read event;
do
    dothething
done
