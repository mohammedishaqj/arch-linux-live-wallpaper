#!/bin/bash

# Window-based Wallpaper Changer for HyDE
# Changes wallpaper based on active window while respecting current theme

# Source HyDE global control to get current theme
source "$HOME/.local/lib/hyde/globalcontrol.sh"

# Configuration
LOG_FILE="/tmp/window-wallpaper.log"
WALLPAPER_CACHE="/tmp/window-wallpaper-cache"
PID_FILE="/tmp/window-wallpaper.pid"

# Initialize
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$WALLPAPER_CACHE"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Cleanup function
cleanup() {
    log_message "Window wallpaper changer stopping"
    rm -f "$PID_FILE"
    exit 0
}

# Set trap for cleanup
trap cleanup SIGTERM SIGINT EXIT

# Function to get current theme and wallpapers
get_current_theme_wallpapers() {
    # Re-source to get updated theme
    source "$HOME/.local/lib/hyde/globalcontrol.sh"
    local current_theme="${HYDE_THEME:-Sci-fi}"
    local wallpaper_dir="$HOME/.config/hyde/themes/$current_theme/wallpapers"
    
    if [[ ! -d "$wallpaper_dir" ]]; then
        log_message "Warning: Wallpaper directory not found: $wallpaper_dir"
        return 1
    fi
    
    # Get all wallpapers from current theme
    local wallpaper_files=()
    while IFS= read -r -d '' file; do
        wallpaper_files+=("$file")
    done < <(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \) -print0 2>/dev/null | sort -z)
    
    echo "${wallpaper_files[@]}"
}

# Function to get wallpaper for specific window class/title
get_wallpaper_for_window() {
    local window_class="$1"
    local window_title="$2"
    local wallpapers=("$@")
    shift 2
    local wallpapers=("$@")
    
    # Define window to wallpaper mapping (you can customize this)
    case "$window_class" in
        "firefox"|"Firefox"|"chromium"|"Chromium"|"google-chrome")
            # Browser - use first wallpaper
            echo "${wallpapers[0]:-}"
            ;;
        "code"|"Code"|"nvim"|"neovim"|"vim")
            # Code editors - use second wallpaper
            echo "${wallpapers[1]:-}"
            ;;
        "kitty"|"alacritty"|"wezterm"|"gnome-terminal"|"dev.warp.Warp")
            # Terminals - use third wallpaper
            echo "${wallpapers[2]:-}"
            ;;
        "discord"|"Discord"|"slack"|"Slack"|"telegram")
            # Communication apps - use fourth wallpaper
            echo "${wallpapers[3]:-}"
            ;;
        "spotify"|"Spotify"|"rhythmbox"|"vlc")
            # Media apps - use fifth wallpaper
            echo "${wallpapers[4]:-}"
            ;;
        "thunar"|"nautilus"|"dolphin"|"pcmanfm")
            # File managers - use sixth wallpaper
            echo "${wallpapers[5]:-}"
            ;;
        "gimp"|"inkscape"|"krita"|"blender")
            # Creative apps - use seventh wallpaper
            echo "${wallpapers[6]:-}"
            ;;
        *)
            # Default - use eighth wallpaper or cycle through available ones
            local hash=$(echo "$window_class$window_title" | md5sum | cut -c1-8)
            local index=$((0x$hash % ${#wallpapers[@]}))
            echo "${wallpapers[$index]:-}"
            ;;
    esac
}

# Function to set wallpaper
set_wallpaper() {
    local wallpaper_path="$1"
    local window_info="$2"
    
    if [[ -n "$wallpaper_path" && -f "$wallpaper_path" ]]; then
        log_message "Setting wallpaper for $window_info: $(basename "$wallpaper_path")"
        echo "Setting wallpaper: $(basename "$wallpaper_path")"
        swww img "$wallpaper_path" --transition-type wipe --transition-duration 1.0
        echo "$wallpaper_path" > "$WALLPAPER_CACHE/current_wallpaper"
    else
        log_message "Warning: Wallpaper not found or empty: $wallpaper_path"
    fi
}

# Function to get active window info
get_active_window_info() {
    local window_info
    window_info=$(hyprctl activewindow -j 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$window_info" ]]; then
        return 1
    fi
    
    local window_class
    local window_title
    window_class=$(echo "$window_info" | jq -r '.class // empty' 2>/dev/null)
    window_title=$(echo "$window_info" | jq -r '.title // empty' 2>/dev/null)
    
    echo "$window_class|$window_title"
}

# Main function
main() {
    # Create PID file
    echo $$ > "$PID_FILE"
    log_message "Starting window-based wallpaper changer (PID: $$)"
    
    local current_window=""
    local current_theme=""
    local wallpapers=()
    
    while true; do
        # Get current theme
        source "$HOME/.local/lib/hyde/globalcontrol.sh"
        local new_theme="${HYDE_THEME:-Sci-fi}"
        
        # Check if theme changed
        if [[ "$new_theme" != "$current_theme" ]]; then
            log_message "Theme changed from '$current_theme' to '$new_theme'"
            current_theme="$new_theme"
            
            # Reload wallpapers for new theme
            local wallpaper_array
            wallpaper_array=$(get_current_theme_wallpapers)
            if [[ $? -eq 0 ]]; then
                read -ra wallpapers <<< "$wallpaper_array"
                log_message "Loaded ${#wallpapers[@]} wallpapers for theme '$current_theme'"
            else
                log_message "Failed to load wallpapers for theme '$current_theme'"
                continue
            fi
        fi
        
        # Get active window info
        local window_info
        window_info=$(get_active_window_info)
        
        if [[ $? -eq 0 && "$window_info" != "$current_window" ]]; then
            current_window="$window_info"
            
            # Parse window info
            IFS='|' read -r window_class window_title <<< "$window_info"
            
            if [[ -n "$window_class" ]]; then
                log_message "Active window changed: class='$window_class', title='$window_title'"
                
                # Get appropriate wallpaper for this window
                local selected_wallpaper
                selected_wallpaper=$(get_wallpaper_for_window "$window_class" "$window_title" "${wallpapers[@]}")
                
                # Set wallpaper if it's different from current
                local current_wallpaper=""
                if [[ -f "$WALLPAPER_CACHE/current_wallpaper" ]]; then
                    current_wallpaper=$(cat "$WALLPAPER_CACHE/current_wallpaper")
                fi
                
                if [[ "$selected_wallpaper" != "$current_wallpaper" ]]; then
                    set_wallpaper "$selected_wallpaper" "$window_class ($window_title)"
                fi
            fi
        fi
        
        sleep 0.3  # Check every 300ms for responsive window switching
    done
}

# Handle script arguments
case "${1:-}" in
    "stop")
        if [[ -f "$PID_FILE" ]]; then
            pid=$(cat "$PID_FILE")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                rm -f "$PID_FILE"
                log_message "Window wallpaper changer stopped (PID: $pid)"
                echo "Window wallpaper changer stopped"
            else
                rm -f "$PID_FILE"
                echo "Window wallpaper changer was not running"
            fi
        else
            echo "Window wallpaper changer was not running"
        fi
        exit 0
        ;;
    "status")
        if [[ -f "$PID_FILE" ]]; then
            pid=$(cat "$PID_FILE")
            if kill -0 "$pid" 2>/dev/null; then
                echo "Window wallpaper changer is running (PID: $pid)"
                if [[ -f "$WALLPAPER_CACHE/current_wallpaper" ]]; then
                    echo "Current wallpaper: $(cat "$WALLPAPER_CACHE/current_wallpaper")"
                fi
            else
                rm -f "$PID_FILE"
                echo "Window wallpaper changer is not running (stale PID file removed)"
            fi
        else
            echo "Window wallpaper changer is not running"
        fi
        exit 0
        ;;
    "log")
        if [[ -f "$LOG_FILE" ]]; then
            tail -f "$LOG_FILE"
        else
            echo "No log file found"
        fi
        exit 0
        ;;
    *)
        # Check if already running using PID file
        if [[ -f "$PID_FILE" ]]; then
            pid=$(cat "$PID_FILE")
            if kill -0 "$pid" 2>/dev/null; then
                echo "Window wallpaper changer is already running (PID: $pid)"
                exit 1
            else
                rm -f "$PID_FILE"
            fi
        fi
        
        # Initialize wallpapers array
        source "$HOME/.local/lib/hyde/globalcontrol.sh"
        current_theme="${HYDE_THEME:-Sci-fi}"
        wallpaper_array=$(get_current_theme_wallpapers)
        if [[ $? -ne 0 ]]; then
            echo "Failed to load wallpapers for theme '$current_theme'"
            exit 1
        fi
        
        # Start main loop
        main
        ;;
esac
