#!/usr/bin/env bash

# Exit on error
set -e

unset HOST
unset USERNAME
unset PASSWORD
unset DELETE_EXTRA
unset NO_INTERACTIVE
unset FILE

red() {
    echo -e "\033[0;31m$1\033[0m"
}

yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

green() {
    echo -e "\033[0;32m$1\033[0m"
}

exit_with_usage() {
    echo "Usage: $0 <file> [options]"
    echo "Options:"
    echo "  -h, --help                 Show this help message"
    echo "  -H, --host <host>          MySQL host"
    echo "  -u, --username <username>  MySQL username"
    echo "  -p, --password <password>  MySQL password"
    echo "  -P, --prompt-password      MySQL password prompt"
    echo "  -D, --delete-extra         Delete extra databases and users"
    echo "  -y, --yes                  Do not ask for confirmation"
    exit 1
}

while test $# -gt 0; do
    case "$1" in
    -h | --help)
        exit_with_usage
        ;;
    -H | --host)
        shift
        HOST=$1
        shift
        ;;
    -u | --username)
        shift
        USERNAME=$1
        shift
        ;;
    -p | --password)
        shift
        PASSWORD=$1
        shift
        ;;
    -P | --prompt-password)
        shift
        read -r -s -p "Password: " PASSWORD
        ;;
    -D | --delete-extra)
        DELETE_EXTRA=1
        shift
        ;;
    -y | --yes)
        NO_INTERACTIVE=1
        shift
        ;;
    *)
        if [ -z "$FILE" ]; then
            FILE=$1
            shift
        else
            echo "Unknown argument: $1"
            exit_with_usage
        fi
        ;;
    esac
done

if [ -z "$FILE" ]; then
    exit_with_usage
fi

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

check_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "${1}: command not found. Please install ${1}."
        exit 1
    fi
}

# Check if mysql, grep, sed and cut are available
check_command mysql
check_command grep
check_command sed
check_command cut

mysql_command() {
    local args=("-N" "-B")
    if [ -n "$HOST" ]; then
        args+=("-h" "$HOST")
    fi
    if [ -n "$USERNAME" ]; then
        args+=("-u" "$USERNAME")
    fi
    if [ -n "$PASSWORD" ]; then
        args+=("-p" "$PASSWORD")
    fi
    mysql "${args[@]}" -e "$1"
}

get_users_from_file() {
    grep '^user:' "$FILE" | cut -d: -f2-
}

get_databases_from_file() {
    grep '^database:' "$FILE" | cut -d: -f2-
}

DATABASES=$(mysql_command "SHOW DATABASES")
USERS=$(mysql_command "SELECT CONCAT(user, '@', host) FROM mysql.user")

drop_database() {
    local db=$1
    if [ -z "$NO_INTERACTIVE" ]; then
        read -r -p "Do you want to delete database '$db'? [y/N] " answer
        if [[ $answer != "y" && $answer != "Y" ]]; then
            return
        fi
    fi
    mysql_command "DROP DATABASE $db"
    echo "[OK] Database '$db' deleted"
}

drop_user() {
    local user=$1
    local host=$2
    if [ -z "$NO_INTERACTIVE" ]; then
        read -r -p "Do you want to delete user '$user'@'$host'? [y/N] " answer
        if [[ $answer != "y" && $answer != "Y" ]]; then
            return
        fi
    fi
    mysql_command "DROP USER '$user'@'$host'"
    echo "[OK] User '$user'@'$host' deleted"
}

check_databases() {
    local file_databases
    local db

    file_databases=$(get_databases_from_file)

    for db in $DATABASES; do
        if ! echo "$file_databases" | grep -qFx "$db"; then
            yellow "[EXTRA] Database '$db' not found in file"
            if [ -n "$DELETE_EXTRA" ]; then
                drop_database "$db"
            fi
        else
            green "[OK] Database '$db' found"
        fi
    done

    for db in $file_databases; do
        if ! echo "$DATABASES" | grep -qFx "$db"; then
            red "[MISSING] Database '$db' missing in MySQL"
        fi
    done
}

check_users() {
    local file_users
    local user

    file_users=$(get_users_from_file | cut -d: -f1) # Remove permissions

    for user in $USERS; do
        if ! echo "$file_users" | grep -qFx "$user"; then
            yellow "[EXTRA] User '$user' not found in file"
            if [ -n "$DELETE_EXTRA" ]; then
                drop_user "$user" "$host"
            fi
        else
            green "[OK] User '$user' found in file"
        fi
    done

    for user in $file_users; do
        if ! echo "$USERS" | grep -qFx "$user"; then
            red "[MISSING] User '$user' missing in MySQL"
        fi
    done
}

check_databases
check_users
# check_permissions # Not implemented yet
