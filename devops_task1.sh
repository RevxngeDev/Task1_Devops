#!/bin/bash


LOG_FILE="/var/log/devops_task.log"
TARGET_DIR=""


log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}


display_help() {
    echo "Usage: $0 [-d target_directory]"
    echo "  -d  Specify target directory for workdirs (optional)"
    exit 0
}


while getopts ":d:h" opt; do
    case $opt in
        d)
            TARGET_DIR="$OPTARG"
            ;;
        h)
            display_help
            ;;
        \?)
            log "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            log "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done


if [ -z "$TARGET_DIR" ]; then
    read -p "Please enter the target directory for workdirs: " TARGET_DIR
fi


if [ ! -d "$TARGET_DIR" ]; then
    log "Creating target directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR" || {
        log "Failed to create target directory $TARGET_DIR"
        exit 1
    }
fi


if ! getent group dev >/dev/null; then
    log "Creating group 'dev'"
    groupadd dev || {
        log "Failed to create group 'dev'"
        exit 1
    }
else
    log "Group 'dev' already exists"
fi


SUDOERS_ENTRY="%dev ALL=(ALL) NOPASSWD:ALL"
if ! grep -q "$SUDOERS_ENTRY" /etc/sudoers; then
    log "Configuring sudo privileges for 'dev' group"
    echo "$SUDOERS_ENTRY" | tee -a /etc/sudoers >/dev/null || {
        log "Failed to configure sudo for 'dev' group"
        exit 1
    }
else
    log "Sudo privileges for 'dev' group already configured"
fi


log "Processing non-system users..."
getent passwd | while IFS=: read -r username _ uid _ _ home _; do
    # Skip system users (UID < 1000) and users with no login shell
    if [ "$uid" -ge 1000 ] && [ -f "$home/.bashrc" ]; then
        # Add user to dev group if not already a member
        if ! id -nG "$username" | grep -qw "dev"; then
            log "Adding user $username to 'dev' group"
            usermod -aG dev "$username" || {
                log "Failed to add user $username to 'dev' group"
                continue
            }
        fi
        
        
        WORKDIR="${TARGET_DIR}/${username}_workdir"
        if [ ! -d "$WORKDIR" ]; then
            log "Creating work directory for $username at $WORKDIR"
            mkdir -p "$WORKDIR" || {
                log "Failed to create directory $WORKDIR"
                continue
            }
            
            # Set permissions
            chown "$username:$(id -gn "$username")" "$WORKDIR" || {
                log "Failed to set ownership for $WORKDIR"
                continue
            }
            
            chmod 660 "$WORKDIR" || {
                log "Failed to set permissions for $WORKDIR"
                continue
            }
            
            
            setfacl -m g:dev:r-x "$WORKDIR" || {
                log "Failed to set ACL for $WORKDIR"
                continue
            }
            
            log "Successfully created and configured $WORKDIR"
        else
            log "Work directory $WORKDIR already exists"
        fi
    fi
done

log "Script execution completed successfully"
exit 0
