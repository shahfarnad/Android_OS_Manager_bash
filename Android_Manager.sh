#!/bin/bash

# ==============================================================================
# Project: Android OS Manager (Shell Simulation)
# Course: Operating Systems Lab
# Description: Interactive, color-coded Bash simulation of Android app lifecycle,
#              process control, permissions, and kernel resource diagnostics.
# ==============================================================================

# ANSI Color Definitions
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color (Reset)

# Setup simulated Android system directories
ANDROID_ROOT="$HOME/AndroidSystem"
APPS_DIR="$ANDROID_ROOT/data/app"
LOG_FILE="$ANDROID_ROOT/system.log"

mkdir -p "$APPS_DIR"
touch "$LOG_FILE"

# Function to log system events with timestamps
log_event() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to pause screen so output is readable during live demo
pause_screen() {
    echo ""
    read -p "$(echo -e "${GRAY}Press [Enter] to return to the main menu...${NC}")"
}

# Function to display ASCII header and live OS status bar
show_banner() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
     _              _           _     _    ___  ____  
    / \   _ __   __| |_ __ ___ (_) __| |  / _ \/ ___| 
   / _ \ | '_ \ / _` | '__/ _ \| |/ _` | | | | \___ \ 
  / ___ \| | | | (_| | | | (_) | | (_| | | |_| |___) |
 /_/   \_\_| |_|\__,_|_|  \___/|_|\__,_|  \___/|____/ 
EOF
    echo -e "${CYAN}         LINUX KERNEL PROCESS & APP SIMULATOR${NC}"
    echo -e "${GRAY}=========================================================${NC}"
    
    # Live status counters
    installed_count=$(ls -1 "$APPS_DIR" 2>/dev/null | wc -l)
    running_count=$(ps -ef | grep "[A]ndroidApp_" | wc -l)
    
    echo -e " ${WHITE}Host:${NC} Ubuntu Linux   ${WHITE}Installed Apps:${NC} ${YELLOW}$installed_count${NC}   ${WHITE}Active PIDs:${NC} ${GREEN}$running_count${NC}"
    echo -e "${GRAY}=========================================================${NC}"
}

# 1. Install a New App (Simulates APK installation)
install_app() {
    echo -e "\n${CYAN}--- [1] Install Android Application ---${NC}"
    read -p "Enter App Name (e.g., WhatsApp, Spotify): " app_name
    
    clean_name=$(echo "$app_name" | tr -d ' ')
    
    if [ -z "$clean_name" ]; then
        echo -e "${RED}[ERROR] App name cannot be empty.${NC}"
        pause_screen
        return
    fi

    if [ -d "$APPS_DIR/$clean_name" ]; then
        echo -e "${YELLOW}[WARNING] App '$clean_name' is already installed!${NC}"
    else
        mkdir -p "$APPS_DIR/$clean_name"
        cat << 'EOF' > "$APPS_DIR/$clean_name/run.sh"
#!/bin/bash
while true; do
    sleep 10
done
EOF
        chmod 755 "$APPS_DIR/$clean_name/run.sh"
        echo "Package: com.android.$clean_name" > "$APPS_DIR/$clean_name/manifest.txt"
        echo "Permissions: Unlocked (755)" >> "$APPS_DIR/$clean_name/manifest.txt"
        
        echo -e "${GREEN}[SUCCESS] '$clean_name' (com.android.$clean_name) installed!${NC}"
        log_event "INSTALLED: com.android.$clean_name"
    fi
    pause_screen
}

# 2. View Installed Apps
list_apps() {
    echo -e "\n${CYAN}--- [2] Installed Applications ---${NC}"
    if [ -z "$(ls -A "$APPS_DIR")" ]; then
        echo -e "${YELLOW}No user apps installed yet.${NC}"
    else
        echo -e "${WHITE}NO.  APP NAME             PERMISSION STATUS${NC}"
        echo -e "${GRAY}---------------------------------------------${NC}"
        idx=1
        for app in "$APPS_DIR"/*; do
            app_base=$(basename "$app")
            if [ -x "$app/run.sh" ]; then
                status="${GREEN}UNLOCKED (755)${NC}"
            else
                status="${RED}LOCKED (444)${NC}"
            fi
            printf "%-4s %-20s %b\n" "$idx." "$app_base" "$status"
            ((idx++))
        done
    fi
}

# 3. Launch an App (Creates a real background Linux process)
launch_app() {
    list_apps
    if [ -z "$(ls -A "$APPS_DIR")" ]; then
        pause_screen
        return
    fi

    echo ""
    read -p "Enter exact name of app to launch: " app_name
    
    if [ -d "$APPS_DIR/$app_name" ]; then
        if [ -x "$APPS_DIR/$app_name/run.sh" ]; then
            # Prevent duplicate launches of the same app
            if pgrep -f "AndroidApp_$app_name" >/dev/null; then
                echo -e "${YELLOW}[INFO] '$app_name' is already running in memory.${NC}"
            else
                bash -c "exec -a AndroidApp_$app_name $APPS_DIR/$app_name/run.sh" &
                pid=$!
                echo -e "${GREEN}[LAUNCHED] '$app_name' started in background (PID: $pid).${NC}"
                log_event "LAUNCHED: $app_name (PID: $pid)"
            fi
        else
            echo -e "${RED}[ACCESS DENIED] '$app_name' is locked. Unlock permissions first!${NC}"
        fi
    else
        echo -e "${RED}[ERROR] App '$app_name' is not installed.${NC}"
    fi
    pause_screen
}

# 4. Task Manager / Force Stop App (Uses ps and kill)
task_manager() {
    echo -e "\n${CYAN}--- [4] Android Task Manager (Active Processes) ---${NC}"
    running=$(ps -ef | grep "[A]ndroidApp_")
    
    if [ -z "$running" ]; then
        echo -e "${YELLOW}No Android apps are currently running in RAM.${NC}"
        pause_screen
        return
    fi

    echo -e "${WHITE}PID      | PROCESS IDENTIFIER${NC}"
    echo -e "${GRAY}---------|-----------------------------------${NC}"
    echo "$running" | awk -v green="$GREEN" -v nc="$NC" '{printf "%s%-8s%s | %s\n", green, $2, nc, $8}'
    
    echo ""
    read -p "Enter PID to Force Stop (or press Enter to cancel): " target_pid
    if [ -n "$target_pid" ]; then
        if kill -9 "$target_pid" 2>/dev/null; then
            echo -e "${GREEN}[STOPPED] Process $target_pid force stopped (SIGKILL sent).${NC}"
            log_event "FORCE STOPPED: PID $target_pid"
        else
            echo -e "${RED}[ERROR] Failed to stop PID $target_pid. Invalid PID.${NC}"
        fi
    fi
    pause_screen
}

# 5. App Permissions Manager (Uses chmod)
manage_permissions() {
    list_apps
    if [ -z "$(ls -A "$APPS_DIR")" ]; then
        pause_screen
        return
    fi

    echo ""
    read -p "Enter App Name to modify permissions: " app_name
    
    if [ ! -d "$APPS_DIR/$app_name" ]; then
        echo -e "${RED}[ERROR] App '$app_name' not found.${NC}"
        pause_screen
        return
    fi

    echo -e "\n${WHITE}Select Permission Mode for '$app_name':${NC}"
    echo -e "  ${RED}1.${NC} Lock App   (Revoke Execute Bit - chmod 444)"
    echo -e "  ${GREEN}2.${NC} Unlock App (Grant Execute Bit  - chmod 755)"
    read -p "Choose option [1-2]: " perm_choice

    case $perm_choice in
        1)
            chmod 444 "$APPS_DIR/$app_name/run.sh"
            echo -e "${RED}[LOCKED] '$app_name' is now read-only (444). Execution blocked.${NC}"
            log_event "PERMISSION REVOKED: $app_name"
            ;;
        2)
            chmod 755 "$APPS_DIR/$app_name/run.sh"
            echo -e "${GREEN}[UNLOCKED] '$app_name' permissions restored (755).${NC}"
            log_event "PERMISSION GRANTED: $app_name"
            ;;
        *)
            echo -e "${RED}[ERROR] Invalid choice.${NC}"
            ;;
    esac
    pause_screen
}

# 6. Device Care: RAM & Storage Monitor (Uses free and df)
device_care() {
    echo -e "\n${CYAN}--- [6] Android Device Care (Kernel Diagnostics) ---${NC}"
    echo -e "${YELLOW}[Volatile Memory / RAM Usage]${NC}"
    free -h | awk 'NR==1 || NR==2 {print "  " $0}'
    
    echo -e "\n${YELLOW}[Internal Storage Partition Usage]${NC}"
    df -h "$HOME" | awk 'NR==1 || NR==2 {print "  " $0}'
    
    log_event "CHECKED: Device Care Diagnostics"
    pause_screen
}

# 7. Uninstall an App (Uses rm -rf)
uninstall_app() {
    list_apps
    if [ -z "$(ls -A "$APPS_DIR")" ]; then
        pause_screen
        return
    fi

    echo ""
    read -p "Enter exact name of app to uninstall: " app_name
    
    if [ -d "$APPS_DIR/$app_name" ]; then
        pkill -f "AndroidApp_$app_name" 2>/dev/null
        rm -rf "$APPS_DIR/$app_name"
        echo -e "${GREEN}[UNINSTALLED] '$app_name' and its sandbox data were removed.${NC}"
        log_event "UNINSTALLED: com.android.$app_name"
    else
        echo -e "${RED}[ERROR] App '$app_name' not found.${NC}"
    fi
    pause_screen
}

# 8. View System Logcat (Uses tail)
view_logs() {
    echo -e "\n${CYAN}--- [8] Android System Logcat (Last 10 Events) ---${NC}"
    echo -e "${GRAY}---------------------------------------------------------${NC}"
    tail -n 10 "$LOG_FILE"
    echo -e "${GRAY}---------------------------------------------------------${NC}"
    pause_screen
}

# ==============================================================================
# Main Execution Loop
# ==============================================================================
log_event "SYSTEM BOOT: Android OS Manager started"

while true; do
    show_banner
    echo -e "  ${CYAN}[1]${NC} Install App (APK Simulator)"
    echo -e "  ${CYAN}[2]${NC} View Installed Apps & Permissions"
    echo -e "  ${CYAN}[3]${NC} Launch App (Spawn Background Process)"
    echo -e "  ${CYAN}[4]${NC} Task Manager (Inspect & Force Stop PIDs)"
    echo -e "  ${CYAN}[5]${NC} App Permissions (Lock / Unlock via chmod)"
    echo -e "  ${CYAN}[6]${NC} Device Care (RAM & Disk Diagnostics)"
    echo -e "  ${CYAN}[7]${NC} Uninstall App (Wipe App Sandbox)"
    echo -e "  ${CYAN}[8]${NC} View System Logs (Logcat)"
    echo -e "  ${RED}[9]${NC} Exit"
    echo -e "${GRAY}=========================================================${NC}"
    read -p "$(echo -e "${WHITE}Select an option [1-9]: ${NC}")" choice

    case $choice in
        1) install_app ;;
        2) list_apps; pause_screen ;;
        3) launch_app ;;
        4) task_manager ;;
        5) manage_permissions ;;
        6) device_care ;;
        7) uninstall_app ;;
        8) view_logs ;;
        9) 
            echo -e "\n${YELLOW}Shutting down Android OS Manager... Goodbye!${NC}"
            log_event "SYSTEM SHUTDOWN"
            exit 0 
            ;;
        *) 
            echo -e "\n${RED}[ERROR] Invalid option. Choose a number between 1 and 9.${NC}"
            sleep 1
            ;;
    esac
done
