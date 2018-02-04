#!/bin/bash

PLUGIN_VERSION="0.0.3"
VAULT_VERSION="0.9.3"

function print_help {
    echo "Usage: bash install.sh OPTIONS"
    echo -e "\nOPTIONS:"
    echo -e "  --linux\tInstall Linux version"
    echo -e "  --darwin\tInstall Darwin (MacOS) version"
    echo -e "  [keybase]\tName of Keybase user to encrypt Vault keys with"
    echo -e "\nSee README.md for dependencies"
}

function gencerts {

  openssl req -subj '/O=My Company Name LTD./C=US/CN=localhost' -new -newkey  rsa:4096 -sha256 -days 3650 -x509 -nodes -keyout root.key -out root.crt
  openssl req -subj '/O=My Company Name LTD./C=US/CN=localhost' -new -newkey rsa:4096 -sha256 -nodes -out vault.csr -keyout vault.key
  echo 000a > serialfile
  touch certindex

cat << EOF > ./vault.cnf
[ ca ]
default_ca = myca

[ myca ]
new_certs_dir = .
unique_subject = no
certificate = ./root.crt
database = ./certindex
private_key = ./root.key
serial = ./serialfile
default_days = 365
default_md = sha256
policy = myca_policy
x509_extensions = myca_extensions
copy_extensions = copy

[ myca_policy ]
commonName = supplied
stateOrProvinceName = optional
countryName = supplied
emailAddress = optional
organizationName = supplied
organizationalUnitName = optional

[ myca_extensions ]
basicConstraints = CA:false
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
subjectAltName = @alt_names
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF

  openssl ca -batch -config vault.cnf -notext -in vault.csr -out vault.crt
  mv *.crt $HOME/etc/vault.d
  mv *.key $HOME/etc/vault.d
  rm certindex
  rm serialfile
  rm serialfile.*
  rm vault.cnf
  rm vault.csr
  rm *.pem
  rm certindex.*

}


function grab_hashitool {
  echo "Tool: $1"
  echo "Version: $2"
  echo "OS: $3"


  wget  --progress=bar:force -O ./$1.zip https://releases.hashicorp.com/$1/$2/$1_$2_$3_amd64.zip
  wget  --progress=bar:force -O ./$1_$2_SHA256SUMS https://releases.hashicorp.com/$1/$2/$1_$2_SHA256SUMS
  wget  --progress=bar:force -O ./$1_$2_SHA256SUMS.sig https://releases.hashicorp.com/$1/$2/$1_$2_SHA256SUMS.sig
  keybase pgp verify -d ./$1_$2_SHA256SUMS.sig -i ./$1_$2_SHA256SUMS
  if [[ $? -eq 2 ]] ; then
    echo "Vault Validation Failed: Signature doesn't verify!"
    exit 2
  fi
  unzip ./$1.zip
  mv ./$1 /usr/local/bin/$1
  rm ./$1_$2_SHA256SUMS.sig
  rm ./$1_$2_SHA256SUMS
  rm ./$1.zip
}


function grab_plugin {
  echo "OS: $1"
  echo "Version: $2"

  wget --progress=bar:force -O ./$1.zip https://github.com/immutability-io/vault-ethereum/releases/download/v$2/vault-ethereum_$2_$1_amd64.zip
  wget --progress=bar:force -O ./SHA256SUMS https://github.com/immutability-io/vault-ethereum/releases/download/v$2/SHA256SUMS
  wget --progress=bar:force -O ./SHA256SUMS.sig https://github.com/immutability-io/vault-ethereum/releases/download/v$2/SHA256SUMS.sig
  keybase pgp verify -d ./SHA256SUMS.sig -i ./SHA256SUMS
  if [[ $? -eq 2 ]] ; then
    echo "Plugin Validation Failed: Signature doesn't verify!"
    exit 2
  fi
  rm ./SHA256SUMS.sig
  rm ./SHA256SUMS
}

function move_plugin {
  echo "OS: $1"
  unzip ./$1.zip
  rm ./$1.zip
  mv ./vault-ethereum $HOME/etc/vault.d/vault_plugins/vault-ethereum
}

function initialize {
  export VAULT_ADDR=https://localhost:8200
  export VAULT_CACERT=$HOME/etc/vault.d/root.crt
  export VAULT_INIT=$(vault operator init -format=json)
  if [[ $? -eq 2 ]] ; then
    echo "Vault initialization failed!"
    exit 2
  fi
  export VAULT_TOKEN=$(echo $VAULT_INIT | jq .root_token | tr -d '"')
  keybase encrypt $KEYBASE -m $VAULT_TOKEN -o ./"$KEYBASE"_VAULT_TOKEN.txt
  if [[ $? -eq 2 ]] ; then
    echo "Keybase encryption failed!"
    exit 2
  fi
  for (( COUNTER=0; COUNTER<5; COUNTER++ ))
  do
    key=$(echo $VAULT_INIT | jq '.unseal_keys_hex['"$COUNTER"']' | tr -d '"')
    vault operator unseal $key
    keybase encrypt $KEYBASE -m $key -o ./"$KEYBASE"_UNSEAL_"$COUNTER".txt
  done
  unset VAULT_INIT
}

function install_plugin {
  vault write sys/plugins/catalog/ethereum-plugin \
        sha_256="$(cat SHA256SUM)" \
        command="vault-ethereum --ca-cert=$HOME/etc/vault.d/root.crt --client-cert=$HOME/etc/vault.d/vault.crt --client-key=$HOME/etc/vault.d/vault.key"

  if [[ $? -eq 2 ]] ; then
    echo "Vault Catalog update failed!"
    exit 2
  fi

  vault secrets enable -path=ethereum -plugin-name=ethereum-plugin plugin
  if [[ $? -eq 2 ]] ; then
    echo "Failed to mount Ethereum plugin!"
    exit 2
  fi
  rm SHA256SUM
}

if [ -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
    # assume Zsh
    shell_profile="zshrc"
elif [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    # assume Bash
    shell_profile="bashrc"
fi

if [ "$1" == "--darwin" ]; then
    PLUGIN_OS="darwin"
elif [ "$1" == "--linux" ]; then
    PLUGIN_OS="linux"
elif [ "$1" == "--help" ]; then
    print_help
    exit 0
else
    print_help
    exit 1
fi
if [ -z "$2" ]; then
    print_help
    exit 0
else
    KEYBASE=$2
fi

if [ -d "$HOME/etc/vault.d" ]; then
    echo "The 'etc/vault.d' directories already exist. Exiting."
    exit 1
fi

mkdir -p $HOME/etc/vault.d/vault_plugins
mkdir -p $HOME/etc/vault.d/data

gencerts

grab_plugin $PLUGIN_OS $PLUGIN_VERSION
move_plugin $PLUGIN_OS
grab_hashitool vault $VAULT_VERSION $PLUGIN_OS

cat << EOF > $HOME/etc/vault.d/vault.hcl
"default_lease_ttl" = "24h"

"max_lease_ttl" = "24h"

"backend" "file" {
  "path" = "$HOME/etc/vault.d/data"
}

"api_addr" = "https://localhost:8200"

"listener" "tcp" {
  "address" = "localhost:8200"

  "tls_cert_file" = "$HOME/etc/vault.d/vault.crt"
  "tls_client_ca_file" = "$HOME/etc/vault.d/root.crt"
  "tls_key_file" = "$HOME/etc/vault.d/vault.key"
}

"plugin_directory" = "$HOME/etc/vault.d/vault_plugins"
EOF

touch "$HOME/.${shell_profile}"
{
    echo '# Vault'
    echo 'export VAULT_ADDR=https://localhost:8200'
    echo 'export VAULT_CACERT=$HOME/etc/vault.d/root.crt'
} >> "$HOME/.${shell_profile}"

unset VAULT_TOKEN
unset VAULT_ADDR
unset VAULT_CACERT

nohup /usr/local/bin/vault server -config $HOME/etc/vault.d/vault.hcl &> /dev/null &
sleep 10

initialize
#install_plugin
unset VAULT_TOKEN

echo -e "$HOME/.${shell_profile} has been modified."
echo "============================================="
echo "The following were set in your environment:"
echo "export VAULT_ADDR=$VAULT_ADDR"
echo -e "export VAULT_CACERT=$VAULT_CACERT"
echo -e "=============================================\n"
echo -e "Please read README.md for your next steps.\n"
