
contents=$(iwgetid -r)

if [[ -z "$contents" ]]; then
    connected=true
else
    connected=false
fi

echo "{\"id\": \"$contents\", \"connected\": $connected}"
