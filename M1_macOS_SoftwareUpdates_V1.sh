#!/bin/bash
#This allows for M1 macs to run macOS Security updates by requiring the user prompt for password to pass to the softwareupdates password required prompt.
#
##Heading to be used for jamfHelper

heading="Security updates required"

##Title to be used for jamfHelper

description="

This process will take approximately 10 minutes. When prompted type your password.

Once completed your computer will reboot and begin the upgrade which will take about 10 minutes."

##Icon to be used for jamfHelper

icon="/path/to/icon"

##Launch jamfHelper

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -iconSize 100 -title "" -icon "$icon" -heading "$heading" -description "$description" -button1 "OK" &

jamfHelperPID=$!
sleep 5

# Pulls the current logged in user and their UID
currUser=$(ls -l /dev/console | awk '{print $3}')
currUserUID=$(id -u "$currUser")

fvPass=$(
# Prompts the user to input their FileVault password using Applescript. This password is used for a SecureToken into the startosinstall.
/bin/launchctl asuser "$currUserUID" sudo -iu "$currUser" /usr/bin/osascript <<APPLESCRIPT
set validatedPass to false
repeat while (validatedPass = false)
-- Prompt the user to enter their filevault password
display dialog "Enter your computer password to start the macOS Security updates" with icon file "System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:FileVaultIcon.icns" default answer "" buttons {"Continue"} with text and hidden answer default button "Continue"
set fvPass to (text returned of result)
display dialog "Re-enter your macOS password to verify it was entered correctly" with text and hidden answer buttons {"Continue"} with icon file "System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:FileVaultIcon.icns" default answer "" default button "Continue"
if text returned of result is equal to fvPass then
set validatedPass to true
fvPass
else
display dialog "The passwords you have entered do not match. Please enter matching passwords." with title "FileVault Password Validation Failed" buttons {"Re-Enter Password"} default button "Re-Enter Password" with icon file messageIcon
end if
end repeat
APPLESCRIPT
)
##Start macOS Security updates.

echo $fvPass | softwareupdate -iaR

exit 0
