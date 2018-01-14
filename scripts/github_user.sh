#!/bin/bash


function print_help {
    echo "Usage: bash mount.sh OPTIONS"
    echo -e "\nOPTIONS:"
    echo -e "  [GitHub user]\tName of GitHub user whose Personal Access Token you are using"
    echo -e "  [keybase]\tName of Keybase user used to encrypt Vault keys"
}

if [ -z "$2" ]; then
    print_help
    exit 0
elif [ "$1" == "--help" ]; then
    print_help
    exit 0
else
  GITHUB_USER=$1
  KEYBASE_USER=$2
fi


export VAULT_TOKEN=$(keybase decrypt -i $KEYBASE_USER"_VAULT_TOKEN.txt")
vault write auth/github/map/users/$GITHUB_USER value=ethereum_root

unset VAULT_TOKEN
