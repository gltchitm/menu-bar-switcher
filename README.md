# MenuBarSwitcher
MenuBarSwitcher is a macOS application for changing the background image depending on a device's locked state.

## Usage
Once opened, select background photos for both the locked and unlocked state. Once you've selected background photos, press the close button and choose "Hide."

## Reopening Options
To reopen the options, you must kill and reopen MenuBarSwitcher.

## Killing MenuBarSwitcher
If you want to kill MenuBarSwitcher after it's been hidden, you can use the Activity Monitor. Choose "Quit" instead of "Force Quit" so MenuBarSwitcher can revert your background photo to its original state before exiting.

## Updating Background Image Paths
To update the background image paths without quitting and reopening MenuBarSwitcher, you can send `SIGHUP` to the MenuBarSwitcher process (i.e. `killall -HUP MenuBarSwitcher`). This will *not* reopen the options menu. If you want to change the background images using this method, change the photos using the `defaults` command before sending `SIGHUP`.

## License
[MIT License](LICENSE)
