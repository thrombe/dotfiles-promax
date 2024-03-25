
contents=$(powerprofilesctl get)

echo "{\"profile\": \"$contents\"}"
