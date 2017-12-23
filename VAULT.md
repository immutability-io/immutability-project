![Immutability](/docs/tagline.png?raw=true "Changes Everything")

# INSTALL VAULT AND VAULT-ETHEREUM PLUG-IN

HashiCorp Vault is a fantastic tool for managing secrets. It is one of those tools that can be daunting to use for a newbie - but, it reveals its elegance over and over through extensive use. HashiCorp provides a very simple mechanism to setup Vault in [developer mode for educational sake](https://www.vaultproject.io/docs/concepts/dev-server.html). I don't leverage this because learning vault in `dev` mode makes it difficult to transition to a production environment wherein you are using plugins. The documentation supporting plugin development and usage is very slight and doesn't help much when you are running Vault in a realistic environment.

So, I have tried to create a very simple, dependency-lite, install of Vault that makes the transition to using it in production less daunting. This amounts to running Vault with TLS (as opposed to in the clear) using a file-based persistence mechanism. In a [real production environment](https://www.vaultproject.io/guides/production.html) you would leverage the Shamir key shards in a more secure fashion.

## Installation script

The provided installation script, [install_vault.sh](/scripts/install_vault.sh), does the following:

* Creates a self-signed CA Certificate and TLS keypair for Vault TLS.
* Downloads and installs the current (0.9.2) version of [HashiCorp Vault](https://www.vaultproject.io/downloads.html) into `/usr/local/bin`. The script uses Keybase to verify the SHA256SUM signature on the Vault release.
* Configures Vault to use TLS and file-based persistence by writing a configuration to your `$HOME` directory: `$HOME/etc/vault.d`.
* Downloads and installs the current (0.0.2) version of [Immutability Vault-Ethereum plugin](https://github.com/immutability-io/vault-ethereum/releases) into `$HOME/etc/vault.d/vault_plugins`. The script uses Keybase to verify the SHA256SUM signature on the plugin release.
* Starts vault (`/usr/local/bin/vault server -config $HOME/etc/vault.d/vault.hcl`), initializes and unseals Vault. The [unseal keys](https://www.vaultproject.io/docs/concepts/seal.html) are encrypted with the supplied Keybase PGP identity and stored in the same directory where the script was run. The [Vault root token](https://www.vaultproject.io/docs/concepts/tokens.html#root-tokens) is similarly encrypted.
* Installs and mounts the Vault-Ethereum plugin at the default path (`ethereum`). Once you get more familiar with Vault concepts, it is likely that you will want several paths for this plugin.

## Install command

If you execute the `install_vault.sh` script without any arguments, the usage will print:

```
$ ./install_vault.sh
Usage: bash install.sh OPTIONS

OPTIONS:
  --linux	Install Linux version
  --darwin	Install Darwin (MacOS) version
  [keybase]	Name of Keybase user to encrypt Vault keys with

See INSTRUCTIONS.md for dependencies
```

So, if I want to install Vault and the Ethereum plugin on my Macbook, I type:

```
$ ./install_vault.sh --darwin immutability
```

I use `--darwin` to select the macOS (don't ask why darwin) and `immutability` because that is my Keybase identity.

The script will emit a lot of output related to `openssl` and `wget`. But when you are done, you will see something like:

```
/Users/immutability/.zshrc has been modified.
=============================================
The following were set in your environment:
export VAULT_ADDR=https://localhost:8200
export VAULT_CACERT=/Users/immutability/etc/vault.d/root.crt
=============================================

Please read INSTRUCTIONS.md for your next steps.

```
When you are done, your directory should look like this (assuming that your user name/group are `myuser:mygroup` and you are using the `immutability` Keybase identity. Don't use the `immutability` Keybase identity of course - use your own.):

```
$ ls -la
total 80
drwxr-xr-x  10 myuser  mygroup   340 Dec 23 13:17 .
drwxr-xr-x   8 myuser  mygroup   272 Dec 22 09:02 ..
-rw-r--r--@  1 myuser  mygroup  7491 Dec 23 13:14 INSTRUCTIONS.md
-rw-r--r--   1 myuser  mygroup  1754 Dec 23 13:17 immutability_UNSEAL_0.txt
-rw-r--r--   1 myuser  mygroup  1754 Dec 23 13:17 immutability_UNSEAL_1.txt
-rw-r--r--   1 myuser  mygroup  1754 Dec 23 13:17 immutability_UNSEAL_2.txt
-rw-r--r--   1 myuser  mygroup  1754 Dec 23 13:17 immutability_UNSEAL_3.txt
-rw-r--r--   1 myuser  mygroup  1754 Dec 23 13:17 immutability_UNSEAL_4.txt
-rw-r--r--   1 myuser  mygroup  1742 Dec 23 13:17 immutability_VAULT_TOKEN.txt
-rwxr-xr-x   1 myuser  mygroup  6503 Dec 23 12:31 install_vault.sh
```

## Access root token

To access your Vault root token, you need to use keybase to decrypt it:

```
$ keybase decrypt -i immutability_VAULT_TOKEN.txt
Message authored by immutability
0c367846-d349-889b-0c83-d7f2662b0a98%

```
With this root token in hand, we can administer the Vault. Best Vault practices are not to use the root token directly, but this is one of those turtles problems with security. Since you have no other users and no other authentication mechanisms set up, you need to kick start the process with the root token. I will describe how to set up these users later (using MFA too!)

For now, your environment needs the following:

```
$ export VAULT_ADDR=https://localhost:8200
$ export VAULT_CACERT=$HOME/etc/vault.d/root.crt
$ export VAULT_TOKEN=0c367846-d349-889b-0c83-d7f2662b0a98
```

If everything worked, you should be able to run some Vault commands.

The current set of Vault policies
```
$ vault policies
default
root
```

The current set of mounts
```
$ vault mounts
Path        Type       Accessor            Plugin           Default TTL  Max TTL  Force No Cache  Replication Behavior  Seal Wrap  Description
cubbyhole/  cubbyhole  cubbyhole_4cb5b99f  n/a              n/a          n/a      false           local                 false      per-token private secret storage
ethereum/   plugin     plugin_4e414655     ethereum-plugin  system       system   false           replicated            false
identity/   identity   identity_f4f4bfb2   n/a              n/a          n/a      false           replicated            false      identity store
secret/     kv         kv_9f623e9b         n/a              system       system   false           replicated            false      key/value secret storage
sys/        system     system_0f49d40b     n/a              n/a          n/a      false           replicated            false      system endpoints used for control, policy and debugging
```

Notice that our Vault Ethereum plugin is indeed mounted... something the plugin enjoyed, no doubt.

## Destruction

If at anytime you wish to kill Vault and remove the environment you can:

```
$ kill -2 $(ps aux | grep '/usr/local/bin/vault server' | awk '{print $2}')
$ rm -fr $HOME/etc/vault.d
```

Once you have destroyed the Vault configuration, your unseal keys and root token are no longer useable.

## Now what?

Well, Vault is installed and running. But, we have no Ethereum nodes running. The next series of instructions describes how to get Ethereum running.
