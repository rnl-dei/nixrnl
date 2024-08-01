#!/usr/bin/env bash

# Exit on error
set -e

# AFS Settings
AFS_USERS_DIR=${AFS_USERS_DIR:-"/afs/.ist.utl.pt/users"}

# Application settings
DISCOVERAFSD_DIR=${DISCOVERAFSD_DIR:-"/var/lib/discoverafsd"}
IMPORTED_USERS_FILE="$DISCOVERAFSD_DIR/imported_users"
LOOP_ITERATION_TIME=${LOOP_ITERATION_TIME:-600} # 600 secs = 10 minutes

DOMAIN_API_URL=${DOMAIN_API_URL:-"http://chaos.winrnl.rnl.tecnico.ulisboa.pt:8888/import_users"}

function get_time_stamp() {
    date "+%F %H:%M:%S"
}

function log {
    echo "$(get_time_stamp) -" "$@" | systemd-cat -t discoverafsd
}

function dump_afs_users() {
    find "$AFS_USERS_DIR" -mindepth 3 -maxdepth 3 -type d -not -name simao -printf "%f\n" | grep -E "ist[0-9]*"
}

function is_user_imported() {
    grep -qFx "$1" "$IMPORTED_USERS_FILE"
}

function add_user_to_domain() {
    curl -s -X GET "$DOMAIN_API_URL?user=$1" &>/dev/null
}

function import_user_if_new() {
    if ! is_user_imported "$1"; then
        log "'$1' is a new user, importing."

        add_user_to_domain "$1"

        echo "$1" >>"$IMPORTED_USERS_FILE"
    fi
}

# Check if we have permissions over our files
touch "$IMPORTED_USERS_FILE" &>/dev/null

if [ ! -w "$IMPORTED_USERS_FILE" ]; then
    echo "No permissions to write in our files. Exiting."
    echo "We should have permissions to write in the following files:"
    echo -e "\t-> $IMPORTED_USERS_FILE"
    exit 1
fi >&2

if ! test -e "$AFS_USERS_DIR"; then
    log "$AFS_USERS_DIR does not exist... aborting"
    exit 1
fi

log "Starting discoverafsd..."

# Starting the main loop, forever searching for AFS users
log "Starting main loop, now searching for new AFS users..."

# Get a previous count going on, so that we can log new loops only if we imported anyone
PREVIOUS_NEW_USERS_COUNT=0

while true; do
    # Start a timer, we want to know how much time importing took
    LOOP_START_TIME=$(date +%s.%N)

    # Count current users to later get a number on how many were imported
    NUM_KNOWN_USERS=$(wc -l "$IMPORTED_USERS_FILE")
    log "Starting loop, $NUM_KNOWN_USERS known users."

    dump_afs_users | while read -r username; do
        import_user_if_new "$username"
    done

    # Calculate how much time it took to run this iteration
    LOOP_END_TIME=$(date +%s.%N)
    DIFF=$(echo "$LOOP_END_TIME - $LOOP_START_TIME" | bc)

    # Get and show how many new users were imported
    NEW_NUM_KNOWN_USERS=$(wc -l "$IMPORTED_USERS_FILE")
    NEW_USERS_COUNT=$((NEW_NUM_KNOWN_USERS - NUM_KNOWN_USERS))

    # But only if new users were added
    if ((NEW_USERS_COUNT != 0)) && ((PREVIOUS_NEW_USERS_COUNT == 0)); then
        log "Finished loop, discovered and imported $NEW_USERS_COUNT new users. Took $DIFF secs."
    fi

    # Check if we reached the loop iteration time, if not, sleep until we reach it
    if (($(echo "$DIFF < $LOOP_ITERATION_TIME" | bc -l))); then
        SLEEP_TIME=$(echo "$LOOP_ITERATION_TIME - $DIFF" | bc -l)
        log "We didn't reach the expected loop iteration time, sleeping for $SLEEP_TIME secs."
        sleep "$SLEEP_TIME"
    fi

    # Save the count for the next loop
    PREVIOUS_NEW_USERS_COUNT=$NEW_USERS_COUNT
done
