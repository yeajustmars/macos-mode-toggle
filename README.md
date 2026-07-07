# macos-mode-toggle

Toggle Apperance in macOS and have the system, Ghostty and Neovim switch themes.

> This is alpha. It's currently hardcoded to my paths.

This is specifically for Aerospace, Ghostty and Neovim. YMMV if you switch things up fron tehre.

I will maybe circle back and make a sort of installer or dynamic variable resolution script for this. For now, it's just backup for me, or anyone that wants to manually tweak it.

# Usage

0. Install `dark-mode-notify`
1. Place `appearance-trigger.sh` somewhere in your PATH and make it executable.
2. Add com.user.appearancechange.plist in `~/Library/LaunchAgents` and enable it.
3. Set a light and dark mode in your `~/.config/ghostty/config.ghostty` file
4. Edit shell script to match your Neovim themes
