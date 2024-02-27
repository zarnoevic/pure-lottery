
[![Author](https://img.shields.io/badge/author-zarnoevic-green)](https://github.com/zarnoevic)
[![License](https://img.shields.io/github/license/zarnoevic/pure-lottery)](https://github.com/zarnoevic/pure-lottery/blob/main/LICENSE.md)
[![Build](https://img.shields.io/github/actions/workflow/status/zarnoevic/pure-lottery/build.yml?branch=main&event=push&label=build)](https://github.com/zarnoevic/pure-lottery/actions/workflows/build.yml)
[![Tests](https://img.shields.io/github/actions/workflow/status/zarnoevic/pure-lottery/test.yml?branch=main&event=push&label=tests)](https://github.com/zarnoevic/pure-lottery/actions/workflows/test.yml)

## Pure Decentralized Lottery

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:
~~~~~~~~
-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
