#!/bin/bash

export VAULT_TOKEN=$(keybase decrypt -i $3_VAULT_TOKEN.txt)

vault write auth/github/mfa_config type=duo
vault write auth/github/duo/access \
    host=$DUO_API_HOSTNAME \
    ikey=$DUO_INTEGRATION_KEY \
    skey=$DUO_SECRET_KEY

vault write auth/github/duo/config \
    user_agent="" \
    username_format="%s-ethereum"

unset VAULT_TOKEN
