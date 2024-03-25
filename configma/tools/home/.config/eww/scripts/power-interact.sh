
contents="$(powerprofilesctl get)"

if [[ "$contents" == "performance" ]]; then
  powerprofilesctl set balanced
elif [[ "$contents" == "balanced" ]]; then
  powerprofilesctl set power-saver
elif [[ "$contents" == "power-saver" ]]; then
  powerprofilesctl set performance
fi

power="$(./scripts/power.sh)"
eww update power="$power"
