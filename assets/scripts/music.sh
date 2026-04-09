#!/bin/bash
song_info=$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null)
status=$(playerctl status 2>/dev/null)

if [[ -n $song_info ]]; then
    if [[ $status == "Playing" ]]; then
        icon="\uf04c"
    else
        icon="\uf04b"
    fi
    echo -e "\uf1bc $icon $song_info"
else
    echo "No song playing"
fi
