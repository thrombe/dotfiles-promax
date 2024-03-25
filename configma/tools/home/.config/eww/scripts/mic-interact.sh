
command="$1"


if [[ "$command" == "up" ]]; then
  wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ 5%+
elif [[ "$command" == "down" ]]; then
  wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%-
elif [[ "$command" == "click" ]]; then
  wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
fi

vol="$(./scripts/mic.sh)"
eww update mic="$vol"
