# Canyacoin - Your Financial Freedom
Community gift to the World.

**Keep running wallet to strengthen the Canyacoin network. Backup your wallet in many locations & keep your coins wallet offline.**

![CAN](https://canya.io/images/Blue-coin-low.png)

- Type: Cryptocurrency
- Ticker: CAN
- Algo: Equihash
- Max supply 21B coins / Current supply: 12500 coins every 2.5 minutes
- Current block size (CAN = 2MB every 2.5 mins)
- Technology / Mother coins: Zcash

## Canyacoin Principles: 
- Anonymous
It is recommended to use anonymous zaddr for all transactions. Public taddrs transactions are also allowed.
- All contributors are welcome and everyone is volunteer - no premine or dev taxes (Satoshi has about 10% of BTC marketcap!)
- Store of value - always POW
- Fully decentralized cryptocurrency
- Decentralized development
Developers are self organized in development pods. Every new dev or team is welcome. All implementations which follow consensus are allowed
- Decentralized mining
As a miner you should not use the biggest pools to follow main principles.
- Easy to mine
Equihash algorithm.
You can use your Desktop PC to mine Canyacoin. Most profitable is GPU mining.
- Decentalized Exchanges
All exchanges are allowed. The best one are decentralized.
- Always immutable - no way to change history!

[Canya.io](https://canya.io)


### Other wallets
- [Canyacoin Windows Wallet]
- [Canyacoin Cold Wallet]

## Roadmap


### Ports:
- RPC port: 
- P2P port: 

Install
-----------------
### Linux

### [Quick guide for beginners](https://github.com/216k155/canyacoin/)

Get dependencies
```{r, engine='bash'}
sudo apt-get install \
      build-essential pkg-config libc6-dev m4 g++-multilib \
      autoconf libtool ncurses-dev unzip git python \
      zlib1g-dev wget bsdmainutils automake
```

Install
```{r, engine='bash'}
# Build
./zcutil/build.sh -j$(nproc)
# fetch key
./zcutil/fetch-params.sh
# Run
./src/canyad
```

### Windows
Windows build is maintained in [canyacoin-win project](https://github.com/216k155/canyacoin/).

Security Warnings
-----------------

**Canyacoin is experimental and a work-in-progress.** Use at your own risk.
