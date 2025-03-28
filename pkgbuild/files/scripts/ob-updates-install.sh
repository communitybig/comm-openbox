#!/usr/bin/env bash
# Script to install updates when the user clicks the polybar icon
# Absolute path to the update check script
UPDATE_CHECK_SCRIPT="$HOME/.config/openbox/scripts/ob-updates-check.sh"

# Debug log
debug_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "/tmp/polybar-updates-install-debug-$USER.log"
}

debug_log "Installation script started"

# Define preferred terminals (in order of preference)
TERMINALS=("kitty" "alacritty" "termite" "xfce4-terminal" "gnome-terminal" "konsole" "x-terminal-emulator")

# Search for an available terminal
TERMINAL=""
for term in "${TERMINALS[@]}"; do
    if command -v "$term" &>/dev/null; then
        TERMINAL="$term"
        debug_log "Found terminal: $TERMINAL"
        break
    fi
done

# If no terminal found, fallback to default
if [ -z "$TERMINAL" ]; then
    TERMINAL="x-terminal-emulator"
    debug_log "No specific terminal found, using default: $TERMINAL"
fi

# Check stored update count
if [ -f "/tmp/updates-count-$USER" ]; then
    updates=$(cat "/tmp/updates-count-$USER" 2>/dev/null || echo "0")
    debug_log "Read update count: $updates"
else
    updates=0
    debug_log "Update count file not found"
fi

# Force a real-time check
debug_log "Checking real-time updates with checkupdates"
realtime_updates=$(checkupdates 2>/dev/null | wc -l || echo "0")
debug_log "Real-time updates (pacman): $realtime_updates"

aur_updates=$(yay -Qua 2>/dev/null | wc -l || echo "0")
debug_log "Real-time updates (AUR): $aur_updates"

total_updates=$((realtime_updates + aur_updates))
debug_log "Total real-time updates: $total_updates"

# Use the most recent value
if [ $total_updates -gt $updates ]; then
    updates=$total_updates
    echo "$updates" > "/tmp/updates-count-$USER"
    debug_log "Updated counter to: $updates"
fi

if [ "$updates" -gt 0 ]; then
    debug_log "Updates available, launching terminal: $TERMINAL"
    
    # Launch terminal to install updates
    case $TERMINAL in
        alacritty)
            $TERMINAL -e bash -c "echo 'Installing $updates updates...' && sudo pacman -Syu && yay -Sua && echo 'Press ENTER to close...' && read"
            ;;
        termite)
            $TERMINAL -e "bash -c 'echo \"Installing $updates updates...\"; sudo pacman -Syu && yay -Sua; echo \"Press ENTER to close...\"; read'"
            ;;
        kitty)
            $TERMINAL -e bash -c "echo 'Installing $updates updates...' && sudo pacman -Syu && yay -Sua && echo 'Press ENTER to close...' && read"
            ;;
        gnome-terminal)
            $TERMINAL -- bash -c "echo 'Installing $updates updates...' && sudo pacman -Syu && yay -Sua && echo 'Press ENTER to close...' && read"
            ;;
        konsole)
            $TERMINAL -e bash -c "echo 'Installing $updates updates...' && sudo pacman -Syu && yay -Sua && echo 'Press ENTER to close...' && read"
            ;;
        xfce4-terminal)
            $TERMINAL -e "bash -c 'echo \"Installing $updates updates...\"; sudo pacman -Syu && yay -Sua; echo \"Press ENTER to close...\"; read'"
            ;;
        *)
            $TERMINAL -e "bash -c 'echo \"Installing $updates updates...\"; sudo pacman -Syu && yay -Sua; echo \"Press ENTER to close...\"; read'"
            ;;
    esac
    
    debug_log "Terminal execution finished"
    
    # After installation, recheck updates
    debug_log "Rechecking updates after installation"
    "$UPDATE_CHECK_SCRIPT" check
else
    # No updates, just notify
    debug_log "No updates available, sending notification"
    notify-send "System Up-to-Date" "Your system is fully updated" -i emblem-default
fi

debug_log "Installation script finished"
