# no-os-primecore
Neo Olympus - Prime Core smart contracts

![Visibility: Open Source](https://img.shields.io/badge/visibility-open%20source-brightgreen)

This project implements the DN-404 standard on top of the [laguna-diamond-foundry](https://github.com/Laguna-Games/laguna-diamond-foundry) framework.

The DN-404 code is adapted from [Vectorized's dn404 implementation](https://github.com/Vectorized/dn404). 

---

## Setup

1. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
2. Install project dependencies: `forge install`
   1. If lib/forge-std is empty: `forge install foundry-rs/forge-std`
   2. If lib/laguna-diamond-foundry is empty: `forge install https://github.com/Laguna-Games/laguna-diamond-foundry`
3. Make a copy of [dotenv.example](dotenv.example) and rename it to `.env`
   1. Edit [.env](.env)
   2. Import or generate a wallet to Foundry (see `cast wallet --help`)
      - Fill in `DEPLOYER_ADDRESS` for a deployer wallet address you will use, and validate it with the `--account <account_name>` option in commands
   3. Fill in any API keys for Etherscan, Basescan, Arbiscan, etc.
4. Load environment variables: `source .env`
5. Compile and test the project: `forge test`
