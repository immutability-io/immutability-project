![Immutability](/docs/tagline.png?raw=true "Changes Everything")

# INSTALL ETHEREUM

The Vault-Ethereum plugin is intended for use in 2 distinct settings:

1. A collaborative (team-based) Ethereum smart contract development organization; and,
2. A production enterprise Ethereum environment.

If you need to use Vault and Ethereum in a production setting, you should seek [professional help](mailto:sales@immtuability,io). And while there is nothing to preclude you from using this the Vault-Ethereum plugin in a production setting; however, given that (at the point of writing this) 1 ETH is valued at $756.94, I will describe how you should build a private Ethereum network.

## Pull Docker Images

[The pull_images.sh script](/scripts/pull_images.sh) will grab all the Docker images needed to build an Ethereum private network. It will also pull down [Portainer, a docker management UI,](https://portainer.io) and an Ethereum Network Stats tool. At the end of this installation, your Portainer UI should show something like this:

![Portainer](/docs/portainer.png?raw=true "Ethereum Network")

**NOTE**: The chain id (or network ID) for the Ethereum network that this Docker image will manage is `1977`. (This is the year my wife was born.) This number will be needed later.

## Ethereum private network

Let's create a Ethereum **private network**. Let's create the Docker network. All Ethereum components will be part of this network. We will use embedded Docker DNS for our nodes.

```sh
$ docker network create ethereum
```

The second thing we have to setup is the Ethereum `bootnode`. For those familiar with the HashiStack, the Ethereum bootnode is similar to [Consul](https://www.consul.io/) -  a service discovery mechanism. (*There is a long discussion that needs to be had about decentralization and the dependence on a few central bootnodes in the Ethereum ecosystem; but, this is not the place for that discussion.*)

### Run the bootnode

The bootnode is run using the [bootnode.sh](/scripts/bootnode.sh) script. This script will stop any prior instances of the bootnode and launch a new one. The bootnode has a URL that is used by Ethereum (`geth`) nodes to discover peers. You can see this URL by running the [getbootnode.sh script](/scripts/getbootnode.sh):

```sh
$ ./getbootnodeurl.sh
enode://a0153d244bd0bd5b8041c5f0171edc8d10e673647d2494e53002b5f956dfa69f3ddff1fafb7a42af927e9867fc65fca28172180574e6a879ab5ed9cdba80d31d@172.18.0.2:30301
```

Of interest here for the HashiCorp audience are 2 things:

1. The mechanism by which the bootnode URL is surfaced is *odd* by normal enterprise standards: the logs for the bootnode process are scraped.
2. The URL is *odd*. The hexadecimal node ID is encoded in the username portion of the URL, separated from the host by an @ sign. The hostname can only be given as an IP address, DNS domain names are not allowed.

This is the first indicator that different ideologies (between the HashiCorp and Ehtereum worlds) are afoot: decentralization and trustlessness are cornerstones of the Ethereum ecosystem.

Important point: In the HashiCorp/12-factor world, distributed systems are what you design for; in the blockchain ecosystem, you target decentralization. These are different, but overlapping, architectural models.

### Run an Ethereum node

The Ethereum network is composed of *bootnodes*, *client* nodes and *mining* nodes. We have started the bootnode. Now, we will start a client node. This node acts as a bridge for clients of the Ethereum network. Most Ethereum wallets require some form of client node to access the network.

To start a node, we use the [runnode.sh script](/scripts/runnode.sh). We name the node (in this case, `wallet`). Later, when we start the Ethereum Network Statistic monitor, we use this name (which is bound to embedded Docker DNS.)

```sh
RPC_PORT=8545 ./runnode.sh wallet
```

The `RPC_PORT=8545` is important. It establishes the port we will use to talk to the Ethereum network.

### Run a Ethereum miner

This is the first part of the exercise where Vault and Ethereum intersect. We will run an node that will mine Ether. This begs the question: *cui bono*? Well, we need to create an Ethereum account on behalf of which the node will mine. Let's use Vault!

#### Create Ethereum account

Remember that chain id? It's the year my wife was born (yes, I've forgotten it too.) We use that as one of the parameters to create an Ethereum account.

```sh
$ vault write ethereum/accounts/miner generate_passphrase=true chain_id=1977
Key     	Value
---     	-----
account 	0x994018b4855d74B418C44b85c6dC7b0b3B7d6eBe
chain_id	1977
rpc_url 	http://localhost:8545
```

Note the `account` parameter returned. That is the Ethereum address we will use as the account our mining node will deposit its earnings into.

#### Run the mining node

Now that we have the Ethereum address, we can start mining:

```sh
$ ETHERBASE=0xae404F50a8441145e9002D67C4b518937072a3AB ./runminer.sh etherbase
Destroying old container ethereum-etherbase...
Error response from daemon: No such container: ethereum-etherbase
Error response from daemon: No such container: ethereum-etherbase
Starting ethereum-etherbase
304c3e03e34a0a94a78ab30df829900a2d5b11a7a55c092a8a712ce4bf04f51c

```

#### IMPORTANT: It takes time to initialize an Ethereum blockchain.















*
