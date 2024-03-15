
selected="$(echo 'suspend' | rofi -dmenu)"

if [[ $selected == 'suspend' ]]; then
  notify-send -t 1000 "suspending"
  systemctl suspend
fi
