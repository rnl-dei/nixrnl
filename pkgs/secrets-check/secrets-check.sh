#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

secrets_dir=${1:-.}
secrets_file=$secrets_dir/secrets.nix

if [ ! -f "$secrets_file" ]; then
  echo -e "$RED\bError:$NC Secrets file not found: $secrets_file"
  echo "Usage: secrets_check.sh <secrets_dir>"
  exit 1
fi

parse_secrets() {
  nix eval --file $secrets_file --json | jq "$@"
}

hash_key() {
  echo $1 | cut -d' ' -f2 | base64 -d | sha256sum | head -c 8 | xxd -r -p | base64 | head -c 6
}

check_key() {
  local key=$1
  local hash_key=$2
  local secret=$3

  if ! grep -q "^-> .\+ $hash_key .\+" "$secrets_dir/$secret"; then
    echo -e "In secret $YELLOW'$secret'$NC missing key $BLUE'$key'$NC"
    invalid_secrets=1
  fi
}

secrets=$(parse_secrets 'to_entries | .[].key' -r)
invalid_secrets=0

for secret in $secrets; do
  while read key; do
    hash_key=$(hash_key "$key")
    check_key "$key" "$hash_key" "$secret"
  done <<< $(parse_secrets ".\"$secret\".publicKeys.[]" -r)

  # Check if there are more keys in the file than expected
  number_of_keys=$(parse_secrets ".\"$secret\".publicKeys | length")
  number_of_keys_in_file=$(grep -c "^-> .\+ [a-zA-Z0-9]\{6\} .\+" "$secrets_dir/$secret")
  if [ $number_of_keys -lt $number_of_keys_in_file ]; then
    echo -e "Secret $YELLOW'$secret'$NC has more $RED$((number_of_keys_in_file - number_of_keys)) keys$NC than expected"
    invalid_secrets=1
  fi

done

if [ $invalid_secrets -eq 1 ]; then
  echo
  echo -e "Run $GREEN'agenix -r'$NC to regenerate the secrets"
  exit 1
else
  echo -e "$GREEN\bAll secrets are up to date $NC"
fi

