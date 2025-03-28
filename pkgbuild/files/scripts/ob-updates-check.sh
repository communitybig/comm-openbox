#!/usr/bin/env bash
# Script to check for available system updates
# Intended for use with polybar in i3wm
# Nerd Fonts icons
ICON_UPDATES="󰚰"   # Circular arrow up icon
ICON_UPDATED="󰄬"   # Circular checkmark icon
ICON_CHECKING="󰑖"  # Circular loading icon

# Colors
COLOR_UPDATES="#f5a70a"   # Color when updates are available (orange)
COLOR_UPDATED="#98c379"   # Color when everything is up-to-date (green)
COLOR_CHECKING="#61afef"  # Color during check (blue)

# File to store the number of updates
UPDATES_FILE="/tmp/updates-count-$USER"
ICON_FILE="/tmp/updates-count-$USER.icon"

# Debug logging function
debug_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "/tmp/polybar-updates-debug-$USER.log"
}

# Function to show status formatted for polybar
show_status() {
    local count=$1
    local icon=$2
    local color=$3

    # Format for polybar with color
    if [ "$count" -gt 0 ]; then
        echo "%{F$color}$icon%{F-} $count"
    else
        echo "%{F$color}$icon%{F-}"
    fi
}

# Check mode: 'check' (verifies updates) or default (displays result)
case "$1" in
    check)
        debug_log "Starting update check"

        # Show checking icon
        show_status 0 "$ICON_CHECKING" "$COLOR_CHECKING" > "$ICON_FILE"
        debug_log "Set checking icon"

        # Check updates using PACMAN and YAY
        pacman_updates=$(checkupdates 2>/dev/null | wc -l || echo "0")
        debug_log "Pacman updates: $pacman_updates"

        aur_updates=$(yay -Qua 2>/dev/null | wc -l || echo "0")
        debug_log "AUR updates: $aur_updates"

        # Total updates
        updates=$((pacman_updates + aur_updates))
        debug_log "Total updates: $updates"

        # Save update count
        echo "$updates" > "$UPDATES_FILE"
        debug_log "Saved update count to $UPDATES_FILE: $updates"

        # Update icon based on result
        if [ "$updates" -gt 0 ]; then
            show_status "$updates" "$ICON_UPDATES" "$COLOR_UPDATES" > "$ICON_FILE"
            debug_log "Set updates-available icon"

            # Send notification
            notify-send "Updates available" "$updates packages can be updated" -i system-software-update
            debug_log "Notification sent"
        else
            show_status 0 "$ICON_UPDATED" "$COLOR_UPDATED" > "$ICON_FILE"
            debug_log "Set system-up-to-date icon"
        fi
        ;;

    *)
        # Read update count from file
        if [ -f "$UPDATES_FILE" ]; then
            count=$(cat "$UPDATES_FILE" 2>/dev/null || echo "0")
            debug_log "Read count from $UPDATES_FILE: $count"
        else
            count=0
            echo "$count" > "$UPDATES_FILE"
            debug_log "File not found, created $UPDATES_FILE with value 0"
        fi

        # Use icon from file if available
        if [ -f "$ICON_FILE" ]; then
            cat "$ICON_FILE"
            debug_log "Using icon from $ICON_FILE"
        else
            # Otherwise, generate icon based on count
            if [ "$count" -gt 0 ]; then
                show_status "$count" "$ICON_UPDATES" "$COLOR_UPDATES"
                debug_log "Generated updates icon based on count: $count"
            else
                show_status 0 "$ICON_UPDATED" "$COLOR_UPDATED"
                debug_log "Generated up-to-date icon based on count: 0"
            fi
        fi

        # If first run or too much time has passed, run check in background
        if [ ! -f "$ICON_FILE" ] || [ ! -f "$UPDATES_FILE" ] || [ $(find "$UPDATES_FILE" -mmin +60 2>/dev/null | wc -l) -gt 0 ]; then
            debug_log "Starting background check"
            ($0 check &)
        fi
        ;;
esac