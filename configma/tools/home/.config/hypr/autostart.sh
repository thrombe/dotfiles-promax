#!/usr/bin/env bash

nm-applet --indicate &

hyprkool daemon -m &

swww init &

swww img ~/0Git/dotfiles-promax/flakes/ai_apps/Fooocus/outputs/2023-12-12/2023-12-12_23-08-35_8144.png

# https://wiki.hyprland.org/Useful-Utilities/Clipboard-Managers/
wl-paste --type text --watch cliphist store &

# pypr &

hypridle &

easyeffects --gapplication-service &

# waybar &
eww open top-bar-0
eww open top-bar-1

dunst
