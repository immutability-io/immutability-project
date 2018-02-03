![Immutability](/docs/tagline.png?raw=true "Changes Everything")

How to play with Vault and Ethereum
=================

# AUDIENCE

It is my experience that the Ethereum community and the community that uses HashiCorp tools (like Vault) are nearly disjoint sets. So, I am trying to develop a set of recipes for bridging this gap. I expect the Vault folks may not need the Vault installation scripts and the Ethereum guys may not need the Ethereum installation scripts; but, both are provided - assuming that a basic set of dependencies are available.

Why should these 2 communities work together (or at least synergistically?) I believe that the blockchain revolution will be best realized as an outcome of the efforts of the Ethereum community. Ethereum is the healthiest, most innovative and least annoying of the various blockchain sects - their vision (a global computer rooted in a trustless ecosystem) is easily the most exciting. Ethereum re-defines *serverless*. And the HashiCorp community has codified the best ideas in the immutable infrastructure space.

That the immutable ledger community hasn't joined forces with the immutable infrastructure community is fairly startling to me. Perhaps this will be a small step towards that synergy.

**Note:** I am working on an article that walks through installation and demonstrates playing with these tools. I will link here when that is finished.

# PREREQUISITES

There a few things you must install before you can play with Vault and Ethereum. The software installation game can be tremendously daunting. I have tried to make it as basic as possible in order to allow you to have a satisfying engagement as soon as possible. So many things can go wrong if basic dependencies aren't satisfied, and often the rabbit hole of establishing dependencies is so fraught with challenges that some developers give up before they have a chance to even start. I want to emphasize that patience is its own reward when you are working with modern technology, but I am sympathetic, so, I will try to keep the basic dependencies to a minimum.


## Operating System

The Vault-Ethereum plugin currently supports macOS and Linux on AMD64 hardware. While golang does support cross compilation for many environments, the `geth` codebase (because of some lower level C-language dependencies) requires [extra work for cross-compilation](https://github.com/ethereum/go-ethereum/wiki/Cross-compiling-Ethereum). I haven't taken on this effort yet (hint), so I have only built releases of the Vault-Ethereum plugin for macOS (darwin) and Linux on AMD64.

I have tested this plugin on these OS versions:

* macOS Sierra Version 10.12.6
* Ubuntu 16.04.3 LTS (GNU/Linux 4.4.0-92-generic x86_64)

## Docker

To avoid some dependency-hell, I use Docker for the Ethereum components of this ecosystem. You need to install Docker to make use of `geth`. If you already have `geth` installed, then you should be fine. But, the Ethereum tools that I describe the installation of require [Docker](https://docs.docker.com/engine/installation/).

I have successfully used this ecosystem with this Docker version. If you have challenges with a higher version, [please let me know](mailto:jeff@immutability.io):

```
$ docker version
Client:
 Version:      17.09.1-ce
 API version:  1.32
 Go version:   go1.8.3
 Git commit:   19e2cf6
 Built:        Thu Dec  7 22:22:25 2017
 OS/Arch:      darwin/amd64

Server:
 Version:      17.09.1-ce
 API version:  1.32 (minimum version 1.12)
 Go version:   go1.8.3
 Git commit:   19e2cf6
 Built:        Thu Dec  7 22:28:28 2017
 OS/Arch:      linux/amd64
 Experimental: false
```

## Keybase

Keybase is a wonderful tool for managing PGP identities. I use it for signature verification and encryption of Vault keys (described later.) My Vault install scripts require the use of Keybase. If you don't want to install Keybase, then you will need to modify the scripts accordingly. The Vault-Ethereum plugin is signed with [Immutability's PGP key](https://keybase.io/immutability). Once you have [installed Keybase](https://keybase.io/download), feel free to reach out to me via Keybase's encrypted chat.

I have successfully used these scripts with this Keybase version. If you have challenges with a higher version, [please let me know](mailto:jeff@immutability.io):

```
$ keybase version
Client:  1.0.38-20171220205307+f5d54bc77
Service: 1.0.38-20171220205307+f5d54bc77
```

That's it for the dependencies, let's have some fun.

1. [INSTALL VAULT AND VAULT-ETHEREUM PLUG-IN](./VAULT.md)
1. [INSTALL ETHEREUM](./ETHEREUM.md)

## Donations?

Send ETH to 0x4169c9508728285e8A9f7945D08645Bb6b3576e5 and you will be blessed in the next life.

![Donations Accepted](/docs/0x4169c9508728285e8A9f7945D08645Bb6b3576e5.png?raw=true "0x4169c9508728285e8A9f7945D08645Bb6b3576e5")
