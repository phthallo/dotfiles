#!/usr/bin/env bash
# Feeds waybar's custom/swaync module.
#
# swaync-client -swb already emits exactly the JSON waybar wants, but its text
# field is the literal "0" when nothing is waiting, which would park a permanent
# zero next to the bell. Blank that one case and pass everything else straight
# through; jq stays unbuffered so the bar updates the moment a notification lands.
exec swaync-client -swb | jq --unbuffered -c '.text = (if (.text // "0") == "0" then "" else .text end)'
