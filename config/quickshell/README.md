# Gruvbox Quickshell configuration

A personal shell for NixOS, Hyprland and UWSM. Install directly in
~/.config/quickshell/ and launch with:

    quickshell --path ~/.config/quickshell/shell.qml

## This cleanup

Removed the disabled GitHub, Pokémon/evolution, weather, Arch update, night-light,
reading-mode, remote-mode and prompt-theme code. Removed obsolete compositor
rounding/motion-blur configuration, and inactive launcher actions. Right-clicking
the workspace indicator now opens the existing overview rather than a retired
side switcher. The settings window title remains `Ajustes` for rule compatibility.
The internal JSON key `showArch` is retained to preserve the Nix-logo visibility
preference; the icon itself is named `Icons.nixos`.

Preserved colors, media/Cava, battery behavior, notifications, brightness tracking,
Bluetooth, calendar, overview, shortcuts, profiles and the wallpaper picker.
Language support is retained; unused dictionary entries were pruned.

Settings: ~/.config/quickshell-settings.json
Launcher history: ~/.config/quickshell-launch-history.json
The update script copies the old pocket-test files if the new files do not exist;
it retains originals and backs up the shell before writing. Use the script before
running this version to preserve preferences. A direct extraction without migration
would load defaults. Existing neutral-name files always take precedence.

## Wallpaper and monitors

Images: ~/.config/wallpaper/
Saved wallpaper link: ~/.local/state/quickshell/current-wallpaper
Hyprpaper configuration and Home Manager initialization remain user-managed.
Settings launches hyprmoncfg in Kitty; its existing window class `pocket-monitors`
is retained for compatibility with the user's keybinding and possible window rules.
The shell never installs or edits Hyprland window rules, GTK settings or portal setup.

## Dependencies

quickshell, Hyprland, hyprpaper, hypridle, hyprlock, cava, brightnessctl,
NetworkManager/nmcli, PipeWire/WirePlumber, jq, shell/coreutils, Kitty and hyprmoncfg.
UPower and BlueZ provide battery and Bluetooth services. UWSM manages the session.
See Settings > Shortcuts for the user's shortcut reference.

## Validation and limits

Qt bytecode compilation checks syntax, not a live compositor session. This update
has not been visually exercised on the user's machine. Test Settings, launcher,
workspace overview, notifications, media, brightness and wallpapers after replacing.
No Hyprland config or Nix configuration is included or changed by the updater.
See NOTICE.md and LICENSE for attribution.
