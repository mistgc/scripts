#!/bin/sh

idle_time=$1

swayidle -w \
    timeout ${idle_time} '~/scripts/swaylock/swaylock.sh' \
    timeout $((${idle_time} + 60)) 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    timeout $((${idle_time} + 120)) 'systemctl suspend' \
    resume 'hyprctl dispatch dpms on'
