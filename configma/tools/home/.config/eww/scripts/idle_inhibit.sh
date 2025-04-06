
pid=$(pidof hypridle)

if [ -z "$pid" ]; then
  status='{"inhibit": false}'
else
  status='{"inhibit": true}'
fi

if [ "$1" == "click" ]; then
  if [ -z "$pid" ]; then
    hypridle &>/dev/null & disown
  else
    pkill hypridle
  fi
  eww update idle="$status"
else
  echo status
fi
