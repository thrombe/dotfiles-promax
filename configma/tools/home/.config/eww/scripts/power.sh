
# contents=$(powerprofilesctl get)

contents="$(asusctl profile --profile-get)"
contents="$(echo "$contents" | tail -n 1 | awk '{print tolower($NF)}')"

echo "{\"profile\": \"$contents\"}"
