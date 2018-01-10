#!/bin/bash


function print_help {
    echo "Usage: bash mount.sh OPTIONS"
    echo -e "\nOPTIONS:"
    echo -e "  [GitHub organization]\tName of GitHub organization you are using for Authentication"
    echo -e "  [GitHub user]\tName of GitHub user whose Personal Access Token you are using"
    echo -e "  [keybase]\tName of Keybase user used to encrypt Vault keys"
}

if [ -z "$3" ]; then
    print_help
    exit 0
elif [ "$1" == "--help" ]; then
    print_help
    exit 0
else
  GITHUB_ORG=$1
  GITHUB_USER=$2
  KEYBASE_USER=$3
fi


export VAULT_TOKEN=$(keybase decrypt -i $KEYBASE_USER"_VAULT_TOKEN.txt")
vault policy-write ethereum_root ethereum_root.hcl
vault auth-enable github
vault write auth/github/config organization=$GITHUB_ORG max_ttl="1h" ttl="1h"
vault write auth/github/map/users/$GITHUB_USER value=ethereum_root

unset VAULT_TOKEN
