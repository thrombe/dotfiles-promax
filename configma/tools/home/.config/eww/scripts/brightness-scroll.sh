
updown="$1"

if [[ "$updown" == "up" ]]; then
  brightnessctl set +5
else
  brightnessctl set 5- --min-value 1
fi
