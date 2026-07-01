#!/usr/bin/env osascript
-- configures Finder window layout on the mounted StudyBar DMG volume
property volumeName : "StudyBar"
property appPosition : {170, 210}
property applicationsPosition : {470, 210}
property windowBounds : {100, 100, 760, 500}

tell application "Finder"
	tell disk volumeName
		open
		set current view of container window to icon view
		set toolbar visible of container window to false
		set statusbar visible of container window to false
		set the bounds of container window to windowBounds
		set viewOptions to the icon view options of container window
		set arrangement of viewOptions to not arranged
		set icon size of viewOptions to 96
		set background picture of viewOptions to file ".background:background.png"
		set position of item "StudyBar.app" of container window to appPosition
		set position of item "Applications" of container window to applicationsPosition
		close
		open
		update without registering applications
		delay 1
	end tell
end tell
