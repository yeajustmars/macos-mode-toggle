#!/bin/bash

LOG_FILE="/tmp/trigger_trace.log"
echo "--- NEW RUN: $(date) ---" > "$LOG_FILE"

# 1. Give macOS a fraction of a second to settle
sleep 0.2

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin"
echo "PATH set." >> "$LOG_FILE"

# 2. Fetch Live Mode
echo "Fetching CURRENT_MODE via AppleScript..." >> "$LOG_FILE"
IS_DARK=$(osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode' 2>/dev/null)

if [ "$IS_DARK" = "true" ]; then
    THEME="_m1_dark"
else
    THEME="_m3_light"
fi
echo "Is Dark: $IS_DARK | Theme: $THEME" >> "$LOG_FILE"

# 3. Update JankyBorders (Detached to prevent hanging)
echo "Executing bordersrc..." >> "$LOG_FILE"
"$HOME/.config/borders/bordersrc" </dev/null >/dev/null 2>&1 &
echo "Borders updated." >> "$LOG_FILE"

# 4. Update chadrc.lua
CHADRC="$HOME/.config/nvim/lua/chadrc.lua"
echo "Updating chadrc.lua..." >> "$LOG_FILE"
sed -i '' -E "s/theme[[:space:]]*=[[:space:]]*['\"][^'\"]*['\"]/theme = \"$THEME\"/" "$CHADRC" >> "$LOG_FILE" 2>&1
echo "chadrc updated." >> "$LOG_FILE"

# 5. Create Lua Payload
echo "Creating Lua payload..." >> "$LOG_FILE"
LUA_PAYLOAD="/tmp/nvchad_theme_switch.lua"
cat <<EOF > "$LUA_PAYLOAD"
require('nvconfig').base46.theme = "$THEME"
require('base46').compile()
require('base46').load_all_highlights()
if #vim.api.nvim_list_uis() > 0 then vim.cmd('redraw!') end
EOF
echo "Payload created." >> "$LOG_FILE"

# 6. Safely apply to Neovim
echo "Searching for Neovim sockets..." >> "$LOG_FILE"
NVIM_SOCKETS=$(find /var/folders -type d -name "nvim.$USER" -exec find {} -type s -name "nvim.*" \; 2>/dev/null)

# THE CRITICAL FIX: The absolute path to your Nix-managed Neovim
NVIM_BIN="/run/current-system/sw/bin/nvim"

if [ -z "$NVIM_SOCKETS" ]; then
    echo "No sockets found. Running headless..." >> "$LOG_FILE"
    "$NVIM_BIN" --headless -c "source $LUA_PAYLOAD" -c "qa" >> "$LOG_FILE" 2>&1
else
    echo "Sockets found. Sending RPC..." >> "$LOG_FILE"
    for addr in $NVIM_SOCKETS; do
        echo "Sending to: $addr" >> "$LOG_FILE"
        "$NVIM_BIN" --headless --server "$addr" --remote-expr "execute('source $LUA_PAYLOAD')" >> "$LOG_FILE" 2>&1
        sleep 0.5
    done
fi
echo "--- RUN COMPLETE ---" >> "$LOG_FILE"
