#!/bin/bash

# internsctl - Custom Linux command
# Version: v0.1.0

# Function to display help information
show_help() {
    cat <<EOF
Usage: internsctl [options] <command>
Options:
  --help           Show help information
  --version        Show version information

Commands:
  cpu getinfo      Get CPU information
  memory getinfo   Get memory information
  user create      Create a new user
  user list        List all regular users
  user list --sudo-only List users with sudo permissions
  file getinfo     Get information about a file
  file getinfo [options] <file-name>
    --size, -s             Print file size
    --permissions, -p      Print file permissions
    --owner, -o            Print file owner
    --last-modified, -m    Print last modified time
EOF
}

# Function to display version information
show_version() {
    echo "v0.1.0"
}

# Function to get CPU information
get_cpu_info() {
    sysctl -n machdep.cpu.brand_string
}

# Function to get memory information
get_memory_info() {
    vm_stat
}

# Function to create a new user
create_user() {
    if [ $# -eq 3 ]; then
        local username="$3"
        sudo useradd -m "$username"
        echo "User $username created successfully."
    else
        echo "Usage: internsctl user create <username>"
    fi
}

# Function to list users
list_users() {
    local sudo_option="$3"
    if [ "$sudo_option" == "--sudo-only" ]; then
        dscl . -read /Groups/admin | grep GroupMembership | cut -d: -f2 | tr -s ' ' '\n' | sort
    else
        dscl . -list /Users | grep -v '^_'
    fi
}

# Function to get file information
get_file_info() {
    local file_name=""
    local option=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            "--size" | "-s")
                option="--size"
                shift
                ;;
            "--permissions" | "-p")
                option="--permissions"
                shift
                ;;
            "--owner" | "-o")
                option="--owner"
                shift
                ;;
            "--last-modified" | "-m")
                option="--last-modified"
                shift
                ;;
            *)
                file_name="$1"
                shift
                ;;
        esac
    done

    if [ -z "$file_name" ]; then
        echo "Usage: internsctl file getinfo [options] <file-name>"
        return
    fi

    if [ ! -e "$file_name" ]; then
        echo "File not found: $file_name"
        return
    fi

    local size=""
    local permissions=""
    local owner=""
    local last_modified=""

    if [ "$(uname)" == "Darwin" ]; then
        # macOS
        size=$(stat -f%z "$file_name")
        permissions=$(stat -f%Sp "$file_name")
        owner=$(stat -f%Su "$file_name")
        last_modified=$(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$file_name")
    else
        # Linux
        size=$(stat -c%s "$file_name")
        permissions=$(stat -c%a "$file_name")
        owner=$(stat -c%U "$file_name")
        last_modified=$(stat -c%y "$file_name")
    fi

    case "$option" in
        "--size") echo "$size" ;;
        "--permissions") echo "$permissions" ;;
        "--owner") echo "$owner" ;;
        "--last-modified") echo "$last_modified" ;;
        *)
            cat <<EOF
File: $file_name
Access: $permissions
Size(B): $size
Owner: $owner
Modify: $last_modified
EOF
    esac
}

# Main script logic
case "$1" in
    "cpu" )
        case "$2" in
            "getinfo" ) get_cpu_info ;;
            * ) show_help ;;
        esac
        ;;
    "memory" )
        case "$2" in
            "getinfo" ) get_memory_info ;;
            * ) show_help ;;
        esac
        ;;
    "user" )
        case "$2" in
            "create" ) create_user "$@" ;;
            "list" ) list_users "$@" ;;
            * ) show_help ;;
        esac
        ;;
    "file" )
        case "$2" in
            "getinfo" ) get_file_info "$@" ;;
            * ) show_help ;;
        esac
        ;;
    "--help" ) show_help ;;
    "--version" ) show_version ;;
    * ) show_help ;;
esac
