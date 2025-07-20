#!/usr/bin/env bash
# dpw@larkspur.localdomain
# 2025-07-20 19:23:34
#

set -eu

#!/bin/bash

# Digital Ocean Spaces s3cmd Configuration Script
# Author: DevOps Engineer
# Description: Automated setup of s3cmd for Digital Ocean Spaces

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print functions
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration variables
ACCESS_KEY=""
SECRET_KEY=""
REGION=""
CONFIG_FILE="$HOME/.s3cfg"

# Available regions
declare -A REGIONS=(
    ["nyc3"]="nyc3.digitaloceanspaces.com"
    ["ams3"]="ams3.digitaloceanspaces.com"
    ["sgp1"]="sgp1.digitaloceanspaces.com"
    ["sfo3"]="sfo3.digitaloceanspaces.com"
    ["fra1"]="fra1.digitaloceanspaces.com"
    ["tor1"]="tor1.digitaloceanspaces.com"
    ["lon1"]="lon1.digitaloceanspaces.com"
    ["blr1"]="blr1.digitaloceanspaces.com"
    ["syd1"]="syd1.digitaloceanspaces.com"
)

# Function to validate input
validate_key() {
    local key="$1"
    local type="$2"
    
    if [[ -z "$key" ]]; then
        print_error "$type cannot be empty"
        return 1
    fi
    
    if [[ "$type" == "Access Key" && ${#key} -ne 20 ]]; then
        print_warning "Access key length (${#key}) doesn't match expected length (20)"
    fi
    
    if [[ "$type" == "Secret Key" && ${#key} -lt 40 ]]; then
        print_warning "Secret key seems shorter than expected"
    fi
    
    return 0
}

# Function to validate region
validate_region() {
    local region="$1"
    
    if [[ -z "${REGIONS[$region]:-}" ]]; then
        print_error "Invalid region: $region"
        print_status "Available regions: ${!REGIONS[*]}"
        return 1
    fi
    
    return 0
}

# Function to install s3cmd
install_s3cmd() {
    if command -v s3cmd &> /dev/null; then
        print_success "s3cmd is already installed ($(s3cmd --version))"
        return 0
    fi
    
    print_status "Installing s3cmd..."
    
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y s3cmd
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y s3cmd
    elif command -v yum &> /dev/null; then
        sudo yum install -y s3cmd
    elif command -v brew &> /dev/null; then
        brew install s3cmd
    elif command -v pip3 &> /dev/null; then
        pip3 install --user s3cmd
    else
        print_error "Cannot install s3cmd automatically. Please install it manually."
        exit 1
    fi
    
    print_success "s3cmd installed successfully"
}

# Function to create configuration
create_config() {
    print_status "Creating s3cmd configuration..."
    
    # Backup existing config if it exists
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%s)"
        print_warning "Existing config backed up"
    fi
    
    # Create the configuration file
    cat > "$CONFIG_FILE" <<EOF
[default]
# Digital Ocean Spaces Configuration - Generated $(date)
access_key = $ACCESS_KEY
secret_key = $SECRET_KEY

# Digital Ocean Spaces Endpoint Configuration
host_base = ${REGIONS[$REGION]}
host_bucket = %(bucket)s.${REGIONS[$REGION]}

# Connection Settings
use_https = True
bucket_location = $REGION

# Authentication and Signature
signature_v2 = False

# SSL/TLS Settings
check_ssl_certificate = True
check_ssl_hostname = True

# Upload Settings
multipart_chunk_size_mb = 50
multipart_max_chunks = 1000

# Performance Settings
socket_timeout = 300
connection_pooling = True

# Output Settings
human_readable_sizes = True
progress_meter = True
verbosity = INFO

# Path Style
website_endpoint = http://%(bucket)s.${REGIONS[$REGION]}/

# Additional Settings
preserve_attrs = True
restore_days = 1
restore_priority = Standard

# Encoding and MIME
encoding = UTF-8
acl_public = False
default_mime_type = binary/octet-stream
guess_mime_type = True

# GPG Settings
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --quiet --no-verbose --batch --yes
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --no-encrypt-to --no-sign --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 --s2k-digest-algo SHA512 --s2k-count 65536 --force-mdc --no-symkey-cache
EOF

    # Set proper permissions
    chmod 600 "$CONFIG_FILE"
    
    print_success "Configuration file created at $CONFIG_FILE"
}

# Function to test configuration
test_config() {
    print_status "Testing s3cmd configuration..."
    
    # Test basic connection
    if s3cmd ls &> /dev/null; then
        print_success "Connection test successful"
        
        # List available spaces
        print_status "Available Spaces:"
        s3cmd ls | while read -r line; do
            echo "  $line"
        done
        
        return 0
    else
        print_error "Connection test failed"
        print_status "Common issues:"
        echo "  - Check your access and secret keys"
        echo "  - Verify the region setting"
        echo "  - Ensure your keys have proper permissions"
        return 1
    fi
}

# Function to show usage examples
show_examples() {
    echo
    echo "=============================="
    echo "  s3cmd Configuration Complete"
    echo "=============================="
    echo "Configuration file: $CONFIG_FILE"
    echo "Region: $REGION"
    echo "Endpoint: ${REGIONS[$REGION]}"
    echo
    echo "Common Usage Examples:"
    echo "  # List all Spaces"
    echo "  s3cmd ls"
    echo
    echo "  # List Space contents"
    echo "  s3cmd ls s3://your-space-name/"
    echo
    echo "  # Upload file"
    echo "  s3cmd put file.txt s3://your-space-name/"
    echo
    echo "  # Upload directory"
    echo "  s3cmd put --recursive directory/ s3://your-space-name/"
    echo
    echo "  # Download file"
    echo "  s3cmd get s3://your-space-name/file.txt"
    echo
    echo "  # Sync directories"
    echo "  s3cmd sync local-dir/ s3://your-space-name/"
    echo
    echo "  # Set public permissions"
    echo "  s3cmd setacl s3://your-space-name/file.txt --acl-public"
    echo
}

# Function to gather credentials interactively
gather_credentials() {
    echo "Digital Ocean Spaces s3cmd Configuration"
    echo "========================================"
    echo
    
    # Get access key
    while true; do
        read -p "Enter your Digital Ocean Spaces Access Key: " ACCESS_KEY
        if validate_key "$ACCESS_KEY" "Access Key"; then
            break
        fi
    done
    
    # Get secret key
    while true; do
        read -s -p "Enter your Digital Ocean Spaces Secret Key: " SECRET_KEY
        echo
        if validate_key "$SECRET_KEY" "Secret Key"; then
            break
        fi
    done
    
    # Get region
    echo
    print_status "Available regions:"
    for region in "${!REGIONS[@]}"; do
        echo "  $region (${REGIONS[$region]})"
    done
    
    while true; do
        read -p "Enter your Digital Ocean Spaces region: " REGION
        if validate_region "$REGION"; then
            break
        fi
    done
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --access-key)
                ACCESS_KEY="$2"
                shift 2
                ;;
            --secret-key)
                SECRET_KEY="$2"
                shift 2
                ;;
            --region)
                REGION="$2"
                shift 2
                ;;
            --config-file)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --access-key KEY     Digital Ocean Spaces access key"
                echo "  --secret-key KEY     Digital Ocean Spaces secret key"
                echo "  --region REGION      Digital Ocean Spaces region"
                echo "  --config-file PATH   Path to s3cmd config file (default: ~/.s3cfg)"
                echo "  --help, -h           Show this help message"
                echo
                echo "Available regions: ${!REGIONS[*]}"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    parse_arguments "$@"
    
    # Install s3cmd if not present
    install_s3cmd
    
    # Gather credentials if not provided via arguments
    if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" || -z "$REGION" ]]; then
        gather_credentials
    else
        validate_key "$ACCESS_KEY" "Access Key"
        validate_key "$SECRET_KEY" "Secret Key"
        validate_region "$REGION"
    fi
    
    # Create configuration
    create_config
    
    # Test configuration
    if test_config; then
        show_examples
        print_success "s3cmd configured successfully for Digital Ocean Spaces!"
    else
        print_error "Configuration completed but testing failed. Please check your credentials."
        exit 1
    fi
}

# Run main function
main "$@"
