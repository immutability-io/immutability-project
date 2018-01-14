#!/bin/bash
function print_help {
    echo "Usage: bash mfa.sh ARGUMENTS"
    echo -e "\nARGUMENTS:"
    echo -e "  [keybase user]"
    echo -e "  [Duo API Hostname]"
    echo -e "  [Duo Integration Key]"
    echo -e "  [Duo Secret Key]"
}

if [ -z "$4" ]; then
    print_help
    exit 0
else
    DUO_API_HOSTNAME=$2
    DUO_INTEGRATION_KEY=$3
    DUO_SECRET_KEY=$4
fi

export VAULT_TOKEN=$(keybase decrypt -i $1_VAULT_TOKEN.txt)

vault write auth/github/mfa_config type=duo
vault write auth/github/duo/access \
    host=$DUO_API_HOSTNAME \
    ikey=$DUO_INTEGRATION_KEY \
    skey=$DUO_SECRET_KEY

vault write auth/github/duo/config \
    user_agent="" \
    username_format="%s-ethereum"

unset VAULT_TOKEN
