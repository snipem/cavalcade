#!/bin/bash
# run: ./reload.sh
osascript -e 'activate application "PICO-8"
tell application "System Events" to keystroke "r" using control down'
