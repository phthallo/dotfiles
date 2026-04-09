#!/bin/sh
battery=$(cat /sys/class/power_supply/BAT*/capacity)
status=$(cat /sys/class/power_supply/BAT*/status)

if [ "$status" = "Charging" ]; then
    icon="\uf0e7"  # FA bolt/lightning
elif [ $battery -ge 90 ]; then
    icon="\uf240"
elif [ $battery -ge 70 ]; then
    icon="\uf241"
elif [ $battery -ge 50 ]; then
    icon="\uf242"
elif [ $battery -ge 25 ]; then
    icon="\uf243"
else
    icon="\uf244"
fi

echo -e "$icon $battery%"
