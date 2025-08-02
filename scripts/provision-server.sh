#!/bin/bash

# ==============================================================================
# Resumable Server Provisioning Script
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
readonly STATE_FILE="/var/log/setup_progress.log"

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

create_user() {
    local task_name="create_user_${USERNAME}"
    check_if_done "$task_name" && return 0
    echo "--- Task: Creating user '$USERNAME' ---"

    if id "$USERNAME" &>/dev/null; then
        echo "User '$USERNAME' already exists."
    else
        adduser --disabled-password --gecos "" "$USERNAME"
    fi
    usermod -aG sudo "$USERNAME"
    echo "User '$USERNAME' created and added to the sudo group."

    mark_as_done "$task_name"
}

setup_ssh_keys() {
    local task_name="setup_ssh_keys_for_${USERNAME}"
    check_if_done "$task_name" && return 0
    echo "--- Task: Setting up SSH keys for '$USERNAME' ---"

    local ssh_dir="/home/$USERNAME/.ssh"
    local auth_keys_file="$ssh_dir/authorized_keys"

    prompt_text="Please perform the following steps in a NEW terminal:
    1. Copy your public SSH key(s) to your clipboard.
    2. Log into this server as '$USERNAME': ssh ${USERNAME}@<your_droplet_ip>
    3. Create the .ssh directory and authorized_keys file:
       mkdir -p ${ssh_dir} && touch ${auth_keys_file}
    4. Set permissions:
       chmod 700 ${ssh_dir} && chmod 600 ${auth_keys_file}
    5. Paste your public key(s) into ${auth_keys_file}.
    6. Log out of the '$USERNAME' session and return here."

    prompt_for_manual_step "$prompt_text"

    mark_as_done "$task_name"
}

configure_passwordless_sudo() {
    local task_name="configure_passwordless_sudo"
    check_if_done "$task_name" && return 0
    echo "--- Task: Configuring passwordless sudo for '$USERNAME' ---"

    # Create a sudoers file instead of editing the main one (safer).
    local sudoers_file="/etc/sudoers.d/90-dpw-nopasswd"
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$sudoers_file"
    chmod 440 "$sudoers_file"
    echo "Sudoers file created at $sudoers_file."

    mark_as_done "$task_name"
}

update_system() {
    local task_name="update_system"
    check_if_done "$task_name" && return 0
    echo "--- Task: Updating system packages (apt update && upgrade) ---"

    apt-get update && apt-get upgrade -y

    mark_as_done "$task_name"
}

install_dev_tools() {
    local task_name="install_dev_tools"
    check_if_done "$task_name" && return 0
    echo "--- Task: Installing core development tools ---"

    # drop out the the script at this point to refine the list
    # pull in just what is needed
    echo "--- Task: Installing core development tools (dropping out here ---"

    apt install -y make xz-utils vim neovim fswatch openssl libssl-dev jq lcov btop gnupg unzip

    mark_as_done "$task_name"

    # NOTE:
    # only necessary if we need g++, which we wont because it's better to develop c++ in osx/linux/docker
    # locally then scp the artifacts to the target
    #
    # apt-get install -y build-essential make binutils autoconf automake libtool libgmp-dev pkg-config \
     # libmpfr-dev libmpc-dev flex bison texinfo curl wget uuid-dev python3-dev libstdc++6 locales openssh-client \
     # xz-utils git vim neovim ninja-build fswatch openssl libssl-dev iputils-ping jq libsodium-dev libncurses-dev \
     # nlohmann-json3-dev procps ca-certificates gnupg software-properties-common \
     # gcc-14 g++-14 clang-format-18 lcov

}

install_rust()  {
    local task_name="install_rust"
    check_if_done "$task_name" && return 0
    echo "--- Task: Installing rust ---"

    sudo -u "$USERNAME" bash -c 'curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y'

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

    apt-get autoremove -y && apt-get clean

    mark_as_done "$task_name"
}

install_valkey() {
    local task_name="install_valkey"
    check_if_done "$task_name" && return 0
    echo "--- Task: Installing Valkey ---"

    apt-get install -y curl gpg
    curl -fsSL https://packages.valkey.io/valkey/gpg.key | gpg --dearmor -o /usr/share/keyrings/valkey-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/valkey-archive-keyring.gpg] https://packages.valkey.io/valkey/ubuntu/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/valkey.list
    apt-get update
    apt-get install -y valkey

    mark_as_done "$task_name"
}

install_caddy() {
    local task_name="install_caddy"
    check_if_done "$task_name" && return 0
    echo "--- Task: Installing Caddy Web Server ---"

    apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' > /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
    apt-get update
    apt-get install caddy

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

    # Create the state file if it doesn't exist
    touch "$STATE_FILE"

    echo "--- Starting Server Provisioning ---"
    echo "Progress is logged in $STATE_FILE. Re-run this script to resume."

    # --- Execute all setup tasks in order ---
    create_user
    setup_ssh_keys
    configure_passwordless_sudo
    update_system
    install_dev_tools
    install_rust
    install_nodejs_nvm
    cleanup_apt
    install_valkey
    install_caddy

    echo -e "\n${GREEN}--- All provisioning tasks completed successfully! ---${NC}"
}

# Run the main function
main "$@"
