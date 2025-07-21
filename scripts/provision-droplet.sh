#!/bin/bash

# ==============================================================================
# Resumable Droplet Provisioning Script
#
# This script sets up a complete development environment. It is idempotent,
# meaning it can be re-run safely. It tracks progress in a state file
# and will skip steps that have already been completed.
#
# login as root and run  ./provision-server.sh
# ==============================================================================

set -eu # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
readonly USERNAME="dpw"
readonly STATE_FILE="/tmp/provision_progress.log"
INSTALL_COMPAT=${INSTALL_COMPAT:-false}

# --- Colors for Output ---
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Checks if a step has already been completed.
# Usage: check_if_done "step_name"
check_if_done() {
    local task_name=$1
    if grep -qFx "$task_name" "$STATE_FILE"; then
        echo -e "${YELLOW}Skipping: '$task_name' is already marked as complete.${NC}"
        return 0 # 0 means "already done"
    else
        return 1 # 1 means "needs to be done"
    fi
}

# Marks a step as complete by appending its name to the state file.
# Usage: mark_as_done "step_name"
mark_as_done() {
    local task_name=$1
    echo "$task_name" >> "$STATE_FILE"
    echo -e "${GREEN}Completed: '$task_name' has been marked as done.${NC}"
}

# Prompts the user to complete a manual step before continuing.
# Usage: prompt_for_manual_step "Your instructions here..."
prompt_for_manual_step() {
    local prompt_text=$1
    echo -e "\n${YELLOW}--- MANUAL ACTION REQUIRED ---${NC}"
    echo -e "$prompt_text"
    read -p "Have you completed this manual step? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting. Please complete the manual step and re-run the script."
        exit 1
    fi
}

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

update_system() {
    local task_name="update_system"
    check_if_done "$task_name" && return 0
    echo "--- Task: Updating system packages (apt update && upgrade) ---"

    apt update && apt upgrade -y

    mark_as_done "$task_name"
}

install_nodejs_nvm() {
    local task_name="install_nodejs_nvm"
    check_if_done "$task_name" && return 0
    echo "--- Task: Installing Node.js via nvm for user '$USERNAME' ---"

    # Run nvm installation as the target user
    sudo -u "$USERNAME" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
    
    # Install latest node and set default, running as the user in a new sourced shell
    sudo -u "$USERNAME" bash -c 'source ~/.nvm/nvm.sh && nvm install node && nvm alias default node'
    
    echo "NVM and latest Node.js installed for $USERNAME."
    mark_as_done "$task_name"
}

cleanup_apt() {
    local task_name="cleanup_apt"
    check_if_done "$task_name" && return 0
    echo "--- Task: Cleaning up apt cache and unused packages ---"

    apt autoremove -y && apt clean

    mark_as_done "$task_name"
}

install_valkey() {
    local task_name="install_valkey"
    check_if_done "$task_name" && return 0
    echo "--- Task: Installing Valkey ---"

    # Install main Valkey package
    sudo apt install -y valkey
    
    # Install compatibility package if requested
    if [[ "$INSTALL_COMPAT" == "true" ]]; then
        print_status "Installing Valkey compatibility binaries..."
        sudo apt install -y valkey-compat
    fi

    mark_as_done "$task_name"
}

install_caddy() {
    local task_name="install_caddy"
    check_if_done "$task_name" && return 0
    echo "--- Task: Installing Caddy Web Server ---"

    rm -f /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    rm -f /etc/apt/sources.list.d/caddy-stable.list

    apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    apt update
    apt install caddy

    systemctl status caddy

    mark_as_done "$task_name"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
       echo "This script must be run with sudo or as root."
       exit 1
    fi

    echo "-- This script will install only after you remove the exit command --"

    exit 0

    # Create the state file if it doesn't exist
    touch "$STATE_FILE"

    echo "--- Starting Server Provisioning ---"
    echo "Progress is logged in $STATE_FILE. Re-run this script to resume."

    # --- Execute all setup tasks in order ---
    update_system
    install_nodejs_nvm
    cleanup_apt

    install_caddy

    # install_valkey

    echo -e "\n${GREEN}--- All provisioning tasks completed successfully! ---${NC}"
}

# Run the main function
main "$@"

