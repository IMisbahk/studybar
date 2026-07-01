#!/usr/bin/env osascript
-- args: bgWidth, bgHeight, appX, appY, appsX, appsY
on run argv
	set bgW to item 1 of argv as integer
	set bgH to item 2 of argv as integer
	set appX to item 3 of argv as integer
	set appY to item 4 of argv as integer
	set appsX to item 5 of argv as integer
	set appsY to item 6 of argv as integer

	-- title bar chrome; keeps background aspect matching the png
	set titleBar to 28
	set winLeft to 200
	set winTop to 120
	set winRight to winLeft + bgW
	set winBottom to winTop + bgH + titleBar

	tell application "Finder"
		tell disk "StudyBar"
			open
			set w to container window
			set current view of w to icon view
			set toolbar visible of w to false
			set statusbar visible of w to false
			set the bounds of w to {winLeft, winTop, winRight, winBottom}
			set viewOptions to the icon view options of w
			set arrangement of viewOptions to not arranged
			set icon size of viewOptions to 96
			set background picture of viewOptions to file ".background:background.png"
			set label position of viewOptions to bottom
			set position of item "StudyBar.app" of w to {appX, appY}
			set position of item "Applications" of w to {appsX, appsY}
			try
				set extension hidden of item ".background" of w to true
			end try
			close
			open
			update without registering applications
			delay 1
		end tell
	end tell
end run
