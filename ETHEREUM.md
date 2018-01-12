![Immutability](/docs/tagline.png?raw=true "Changes Everything")

# INSTALL ETHEREUM

The Vault-Ethereum plugin is intended for use in 2 distinct settings:

1. A collaborative (team-based) Ethereum smart contract development organization; and,
2. A production enterprise Ethereum environment.

If you need to use Vault and Ethereum in a production setting, you should seek [professional help](mailto:sales@immtuability,io). And while there is nothing to preclude you from using this the Vault-Ethereum plugin in a production setting; however, given that (at the point of writing this) 1 ETH is valued at $756.94, I will describe how you should build a private Ethereum network.

## Pull Docker Images

[The pull_images.sh script](/scripts/pull_images.sh) will grab all the Docker images needed to build an Ethereum private network. It will also pull down [Portainer, a docker management UI,](https://portainer.io) and an Ethereum Network Stats tool.

## Portainer

Since we are creating a Docker network and running several Docker containers, I think it may be useful to have a nice, lightweight management UI for the Docker components. I use [Portainer](https://portainer.io/) - I'm sure  there are others that are as good or even better.

Running Portainer is pretty easy. First, you have to create a directory that you will mount for the persistence of Portainer's data. I use `$HOME/etc/portainer`. You can use whatever you like:

```sh
$ docker volume create portainer_data
$ docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
```

Point your browser to `http://localhost:9000/#/dashboard` and you should see something like this:

![Portainer](/docs/portainer_dashboard.png?raw=true "Portainer Dashboard")

## Ethereum private network

Let's create a Ethereum **private network**. Let's create the Docker network. All Ethereum components will be part of this network. We will use embedded Docker DNS for our nodes.

```sh
$ docker network create ethereum
```

The second thing we have to setup is the Ethereum `bootnode`. For those familiar with the HashiStack, the Ethereum bootnode is similar to [Consul](https://www.consul.io/) -  a service discovery mechanism. (*There is a long discussion that needs to be had about decentralization and the dependence on a few central bootnodes in the Ethereum ecosystem; but, this is not the place for that discussion.*)

**NOTE**: The chain id (or network ID) for the **private** Ethereum network that this Docker image will manage is `1977`. (This is the year my wife was born.) This number will be needed later. Here is a list of the current known public chain IDs:

* `0`: Olympic, Ethereum public pre-release testnet
* `1`: Frontier, Homestead, Metropolis, the Ethereum public main network
* `1`: Classic, the (un)forked public Ethereum Classic main network, `chain ID 61`
* `1`: Expanse, an alternative Ethereum implementation, `chain ID 2`
* `2`: Morden, the public Ethereum testnet, now Ethereum Classic testnet
* `3`: Ropsten, the public cross-client Ethereum testnet
* `4`: Rinkeby, the public Geth Ethereum testnet
* `42`: Kovan, the public Parity Ethereum testnet
* `7762959`: Musicoin, the music blockchain

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
$ RPC_PORT=8546 ETHERBASE=0x994018b4855d74B418C44b85c6dC7b0b3B7d6eBe ./runminer.sh etherbase
Destroying old container ethereum-etherbase...
Error response from daemon: No such container: ethereum-etherbase
Error response from daemon: No such container: ethereum-etherbase
Starting ethereum-etherbase
304c3e03e34a0a94a78ab30df829900a2d5b11a7a55c092a8a712ce4bf04f51c

```

**Note**: We expose the RPC_PORT as 8546 - this is the port that clients *outside of the Docker network* use to communication with this node. Inside the Docker network, clients use the default RPC_PORT=8545. A quick look at the Portainer containers shows the port exposure:

![RPC Ports](/docs/rpc_ports.png?raw=true "Ethereuem RPC Ports")

#### IMPORTANT: It takes time to initialize an Ethereum blockchain.

If this is the first time you have started your nodes, then you need to wait (maybe as long as 45 minutes) for the [DAG](https://ethereum.stackexchange.com/questions/1993/what-actually-is-a-dag) to be initialized. Go grab a cup of coffee. Play with your kids. But don't just stare at `docker logs ethereum-etherbase`!

#### How do I know Ethereum is ready?

You know you are ready to send transactions (send ETH or deploy contracts) when you see the following kinds of messages in the log file of your mining node: ``

```
$ docker logs ethereum-etherbase
...
INFO [12-24|13:54:57] 🔗 block reached canonical chain          number=71283 hash=4de339…fe1427
INFO [12-24|13:54:57] 🔨 mined potential block                  number=71288 hash=f2d78f…105d77
DEBUG[12-24|13:54:57] Reinjecting stale transactions           count=0
INFO [12-24|13:54:57] Commit new mining work                   number=71289 txs=0 uncles=0 elapsed=445.759µs
...
```

### Run Ethereum Network Stats

It is fun to look at the state of your Ethereum network, even if it only (in this exercise) has 2 nodes:

![Ethereuem Network Stats](/docs/ethstats.png?raw=true "Ethereuem Network Stats")

At some point, I want to integrate **real service discovery** into this private Ethereum ecosystem. (I.e., I want to make everything use [HashiCorp Consul](https://www.consul.io/).) At present, we have to deal with the static nature of the toolset.

The Ethereum Network Stats system is composed of 2 components:

1. The data collection/analysis component: [Ethereum Network Intelligence API](https://github.com/immutability-io/eth-net-intelligence-api)
2. The visualization portal: [Ethereum Network Stats](https://github.com/immutability-io/eth-netstats)

This system works as follows:

* The Ethereum Network Intelligence API component monitors the nodes in the Ethereum network.
* The Ethereum Network Intelligence API sends data (via WebSockets) to the Ethereum Network Stats portal.
* The Ethereum Network Intelligence API authenticates to the Ethereum Network Stats portal via a shared secret: `WS_SECRET`. The secret is encoded into the configuration file for the Ethereum Network Intelligence API and passed into the environment of the Ethereum Network Stats portal.

#### Docker DNS

The Ethereum Network Intelligence API needs to know the network addresses of the nodes in the Ethereum network as well as the Ethereum Network Stats portal. We leverage Docker DNS to make this a little more elegant. Therefore it is important to use the `--network-alias` in your `docker run` commands.

##### Ethereum Network Stats portal

First generate a secret. I use a [simple little utility to generate strong passphrases](https://github.com/immutability-io/pass):

```sh
$ WS_SECRET=$(pass -separator -)
$ echo $WS_SECRET
fiftieth-marry-patronize-barrack-parish-denim
```

Now start the portal. We expose `port 3000` on the container. The DNS name for the portal is `ethstats`:

```sh
$ docker run -d -p 3000:3000  --network ethereum --name=ethstats --network-alias=ethstats -e WS_SECRET=$WS_SECRET immutability/ethstats
```

##### Ethereum Network Intelligence API

Because of the static nature of service discovery with these tools, the Ethereum Network Intelligence API should be run after the portal (above) is started. You need to provide a configuration file that tells the Ethereum Network Intelligence API what endpoints it should connect to. This file will depend on your individual configuration. Mine (which should be compatible with yours if you followed the above steps exactly) looks like (note the use of Docker DNS):

```sh
$ cat ../app.json
[
  {
    "name": "ethereum-wallet",
    "cwd": ".",
    "script": "app.js",
    "log_date_format": "YYYY-MM-DD HH:mm Z",
    "merge_logs": false,
    "watch": false,
    "exec_interpreter": "node",
    "exec_mode": "fork_mode",
    "env": {
      "NODE_ENV": "private",
      "RPC_HOST": "ethereum-wallet",
      "RPC_PORT": "8545",
      "INSTANCE_NAME": "ethereum-wallet",
      "WS_SERVER": "http://ethstats:3000",
      "WS_SECRET": "fiftieth-marry-patronize-barrack-parish-denim"
    }
  },
  {
    "name": "ethereum-etherbase",
    "cwd": ".",
    "script": "app.js",
    "log_date_format": "YYYY-MM-DD HH:mm Z",
    "merge_logs": false,
    "watch": false,
    "exec_interpreter": "node",
    "exec_mode": "fork_mode",
    "env": {
      "NODE_ENV": "private",
      "RPC_HOST": "ethereum-etherbase",
      "RPC_PORT": "8545",
      "INSTANCE_NAME": "ethereum-etherbase",
      "WS_SERVER": "http://ethstats:3000",
      "WS_SECRET": "fiftieth-marry-patronize-barrack-parish-denim"
    }
  }
]
```

Now we launch the Ethereum Network Intelligence API:

```sh
docker run -d -P --name ethnetintel --network ethereum --network-alias ethnetintel -v $HOME/eth-net-intelligence-api/app.json:/opt/app.json immutability/eth-net-intelligence-api:latest
```

You can see the Ethereum Network Statistic by pointing your browser at `http://localhost:3000`

## Playground Ready!

At the end of this installation, your Portainer UI should show something like this:

![Portainer](/docs/portainer.png?raw=true "Ethereum Network")



*
