
contents=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)

if [[ "$contents" == *"[MUTED]" ]]; then
    muted=true
else
    muted=false
fi

vol=$(echo $contents | cut -d ' ' -f2)
vol=$(echo "$vol * 100" | kalker | cut -d ' ' -f2)
echo "{\"level\": $vol, \"muted\": $muted}"
