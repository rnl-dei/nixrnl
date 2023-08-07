#!/usr/bin/env bash

# This script will deploy your NixOS configuration to a remote host.
# It will use the NixOS configuration from the flake in the current directory.
# It will also copy the ssh host key using agenix to the remote host.
#
# Made by nuno.alves <at> rnl.tecnico.ulisboa.pt

# Arguments:
# $1: The flake configuration to deploy. Example: .#your-host
# $2: The remote host. Example: root@yourip
# $3: Optional: name of the agenix encrypted ssh host key. Example: host-keys/your-host.age
# --agenix-args: Optional: arguments to pass to agenix. Example: --agenix-args="-d"
# --nixos-anywhere-args: Optional: arguments to pass to nixos-anywhere. Example: --nixos-anywhere-args="--extra-files /etc/nixos"

# Check if agenix is installed
if ! command -v agenix &> /dev/null; then
  echo "agenix is not installed. Please install it first."
  exit 1
fi

# Check if nixos-anywhere is installed
if ! command -v nixos-anywhere &> /dev/null; then
  echo "nixos-anywhere is not installed. Please install it first."
  exit 1
fi

# Get extra agenix arguments
agenix_args=$(echo "$@" | sed -n 's/.*--agenix-args="\([^"]*\)".*/\1/p')

# Get extra nixos-anywhere arguments
nixos_anywhere_args=$(echo "$@" | sed -n 's/.*--nixos-anywhere-args="\([^"]*\)".*/\1/p')


# Check if have 2 or 3 arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 <flake configuration> <remote host> [path to encrypted ssh host key]"
  exit 1
fi

# Ensure that the options are corret
echo -e "Flake configuration: \e[1;35m$1\e[0m"
echo -e "Remote host: \e[1;31m$2\e[0m"
if [ $# -eq 3 ]; then
  echo -e "Path to encrypted ssh host key: \e[1;33m$3\e[0m"
else
  echo -e "Path to encrypted ssh host key: None"
fi
if [ ! -z "$agenix_args" ]; then
  echo "Agenix arguments: $agenix_args"
fi
if [ ! -z "$nixos_anywhere_args" ]; then
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

# If have 3 arguments, copy the ssh host key to the temporary directory
if [ $# -eq 3 ]; then
  # Create the directory where sshd expects to find the host keys
  install -d -m755 "$temp/etc/ssh"

  # Decrypt your private key from the password store and copy it to the temporary directory
  pushd ./secrets
  agenix -d $3 $agenix_args > "$temp/etc/ssh/ssh_host_ed25519_key"
  popd

  # Set the correct permissions so sshd will accept the key
  chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"
fi

# Install NixOS to the host system with our secrets
nixos-anywhere $nixos_anywhere_args --extra-files "$temp" --flake $1 $2
