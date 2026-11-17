# Lock update

Copy this folder's files into ~/.config/quickshell-lock while unlocked.
Keep the existing PAM configuration and Hypridle lock_cmd:
    bash /home/danil/.config/quickshell-lock/run-lock.sh

Start the prepared lock process once for this session:
    uwsm app -- bash /home/danil/.config/quickshell-lock/run-daemon.sh

It stays running without locking. Add this inside your existing Hyprland
hl.on("hyprland.start", function() ... end) callback for future sessions:
    hl.exec_cmd("uwsm app -- bash /home/danil/.config/quickshell-lock/run-daemon.sh")

Test:
    loginctl lock-session

The menu/keybind can continue calling loginctl lock-session. run-lock.sh contacts
the resident process; if absent, it starts one and requests a lock. It uses the
existing python3, bash, coreutils, flock and quickshell. No Nix rebuild required.

Preferences.qml:
- notchColor is explicitly #1d2021 (not inherited from a saved black shell color).
- dimAmount is 0.55 (was 0.42).
- animationDuration remains 650ms.

Wrong passwords: the field stays read-only while authentication is pending.
After the result it waits 200ms, then enables typing. Error feedback disappears
when typing resumes. PAM's own authentication/failure timing is unchanged.

The daemon preloads the wallpaper present at startup. Each lock command resolves
the current wallpaper symlink; a different wallpaper is decoded before locking,
with a 1200ms maximum wait and an opaque fallback if loading fails. Thus the
first lock after changing wallpaper can still have a loading pause.
To prewarm a changed wallpaper before your next lock, restart the daemon while
UNLOCKED, or use the lock.prepare IPC function with its file URL. Do not kill
the lock process while locked. Settings changes also require an unlocked restart.

For this first installation no old daemon exists: the old lock exits on unlock.
For later updates, while unlocked:
    quickshell ipc --path /home/danil/.config/quickshell-lock/shell.qml call lock stop
Then start run-daemon.sh again. stop refuses to exit while locking or locked.

Open windows are covered immediately by opaque session-lock surfaces. Their
actual disappearance is controlled by the compositor. A screenshot crossfade
would be a separate feature, requiring capturing the desktop before locking;
this update does not capture private windows or postpone locking for an exit
animation. The wallpaper dim/clock/pill animation remains.

Validated: QML compilation, shell syntax, controller tests with mocked PAM and
Wayland. Real Hyprland, PAM and multi-monitor/suspend behavior require testing
on your machine. Keep inhibit_sleep = 3 in Hypridle and test suspend after a
successful manual lock/unlock. There is no IPC unlock method.
