#!/usr/bin/env bash

# This script will deploy your NixOS configuration to a remote host.
# It will use the NixOS configuration from the flake in the current directory.
# It will also copy the ssh host key using agenix to the remote host.
#
# Made by nuno.alves <at> rnl.tecnico.ulisboa.pt

# Arguments:
# $1: The flake configuration to deploy. Example: .#your-host
# $2: The remote host. Example: root@yourip
# $3: Optional: name of the agenix encrypted ssh host key. Example: your-host
# --agenix-args: Optional: arguments to pass to agenix. Example: --agenix-args="-d"
# --nixos-anywhere-args: Optional: arguments to pass to nixos-anywhere. Example: --nixos-anywhere-args="--extra-files /etc/nixos"

set -e

# Check if agenix is installed
if ! command -v agenix &>/dev/null; then
    echo "agenix is not installed. Please install it first."
    exit 1
fi

# Check if nixos-anywhere is installed
if ! command -v nixos-anywhere &>/dev/null; then
    echo "nixos-anywhere is not installed. Please install it first."
    exit 1
fi

# Check if have 2 or 3 arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <flake configuration> <remote host> [path to encrypted ssh host key]"
    exit 1
fi
flake_path=$1
remote_host=$2
if [ $# -gt 2 ]; then
    host_key_name=$3
    shift
fi
shift 2

# Get extra arguments
unset error
for arg in "$@"; do
    k="$(echo "$arg" | cut -d= -f1)"
    v="$(echo "$arg" | cut -d= -f2)"
    case $k in
    --agenix-args)
        agenix_args="$v"
        ;;
    --nixos-anywhere-args)
        nixos_anywhere_args="$v"
        ;;
    *)
        echo "Unknown argument: $arg"
        error=1
        ;;
    esac
done
if [ -n "$error" ]; then
    exit 1
fi

# Ensure that the options are correct
echo -e "Flake configuration: \e[1;35m$flake_path\e[0m"
echo -e "Remote host: \e[1;31m$remote_host\e[0m"
if [ -n "$host_key_name" ]; then
    echo -e "Path to encrypted ssh host key: \e[1;33m$host_key_name\e[0m"
else
    echo -e "Path to encrypted ssh host key: None"
fi
if [ -n "$agenix_args" ]; then
    echo "Agenix arguments: $agenix_args"
fi
if [ -n "$nixos_anywhere_args" ]; then
    echo "NixOS Anywhere arguments: $nixos_anywhere_args"
fi

read -p "Are these options correct? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting..."
    exit 1
fi

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
    rm -rf "$temp"
}
trap cleanup EXIT

# If provided, copy the ssh host key to the temporary directory
if [ -n "$host_key_name" ]; then
    # Create the directory where sshd expects to find the host keys
    install -d -m755 "$temp/etc/ssh"

    # Decrypt your private key from the password store and copy it to the temporary directory
    pushd ./secrets || exit 1
    HOST_KEY="host-keys/$host_key_name.age"
    # shellcheck disable=SC2086
    agenix -d "$HOST_KEY" $agenix_args >"$temp/etc/ssh/ssh_host_ed25519_key"
    popd || exit 1

    # Set the correct permissions so sshd will accept the key
    chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"
fi

# Install NixOS to the host system with our secrets
# shellcheck disable=SC2086
nixos-anywhere $nixos_anywhere_args --extra-files "$temp" --flake "$flake_path" "$remote_host"
