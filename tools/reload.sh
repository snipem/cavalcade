#!/bin/bash
# run: ./reload.sh
osascript -e '
    tell application "System Events"
        set activeApp to name of first application process whose frontmost is true
        activate application "PICO-8"
        delay 0.5
        key down command
        delay 0.2
        keystroke "r"
        key up command
        activate application activeApp
    end tell
'
