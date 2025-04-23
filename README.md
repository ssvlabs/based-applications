# :construction_worker: :closed_lock_with_key: __Based Applications Contracts__

:construction: CAUTION: This repo is currently under **heavy development!** :construction:

[![CI Tests](https://github.com/ssvlabs/based-applications/actions/workflows/tests.yml/badge.svg)](https://github.com/ssvlabs/based-applications/actions/workflows/tests.yml)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)

&nbsp;

## :book: _Description_

This repository contains the SSV Based Applications Platform Contracts.

The contracts are organized under the `src/` directory into two main folders:

- **`core/`**: contains the main platform contract: `SSVBasedApps.sol`;
  
- **`middleware/`** contains the module contracts to build a based application. 

### **The Core Platform**

The core contract is build in a diamond-like pattern: 

- **`SSVBasedApps.sol`** – Core contract where all the functions are declared and via an internal proxy it redirects to the right implementation. 

The functions are implemented in 3 different modules:
  
- **`StrategyManager.sol`** – Implements functions related to strategies, validator balance delegation, opting-in to bApp, and slashing;
  
- **`BasedAppsManager.sol`** – Implements functions related to bApps like the registration and update the metadata;
  
- **`PlatformManager.sol`** – Implements functions for updating the global variables like timelocks length, max number of shares, etc. The variable update process will be handled by the SSV DAO.
  
### **The Middleware**

This `middleware` folder contains the modules for building a bapp: 

- **`modules/core`**: the base layer for a bApp to be compliant and be recognized by the system;

- **`examples`**: contains example of working compliant bApps.

&nbsp;

## :page_with_curl: _Instructions_

**1)** Fire up your favorite console & clone this repo somewhere:

__`❍ git clone https://github.com/ssvlabs/based-applications.git`__

**2)** After selecting the right branch, enter this directory & install dependencies:

__`❍ forge install`__

**3)** Compile the contracts:

__`❍ forge build`__

**4)** Set the tests going!

__`❍ forge test`__

&nbsp;

## 🔨 _Slashing Mechanism_

The `slash` function allows for the reduction of a strategy’s token balance under specific conditions, either as a penalty or to enforce protocol-defined behavior. Slashing can happen in two distinct modes, depending on whether:

**1)** The bApp is a compliant smart contract;

**2)** The bApp is a non-compliant smart contract or an EOA.

### 🧠 Compliant BApp

If the bApp is a compliant contract implementing the required interface `IBasedApp`,

The slash function of the bApp is called: `(success, receiver, exit) = IBasedApp(bApp).slash(...)`

*	`data` parameter is forwarded and may act as a proof or auxiliary input.

*	The bApp decides:

    *	Who receives the slashed funds by setting the `receiver` fund, it can burn by setting the receiver as `address(0)`;

    *	Whether to exit the strategy or adjust obligations;

    *	If `exit == true`, the strategy is exited and the obligation value is set to 0;

    *	Otherwise, obligations are adjusted proportionally based on remaining balances, the new obligated amount is set to the previous one less the slashed amount;

    *	Funds are credited to the receiver in the slashing fund.

### 🔐 Non-compliant bApp (EOA or Non-compliant Contract)

If the bApp is an EOA or does not comply with the required interface:

*	Only the bApp itself can invoke slashing;

*	The receiver of slashed funds is forcibly set to the bApp itself;

*	The strategy is always exited (no obligation adjustment);

*	Funds are added to the bApp’s slashing fund.

### ⏳ Post Slashing

⚠️ Important: After an obligation has been exited, it can be updated again to a value greater than 0, but only after a 14-day obligation timelock.

This acts as a safeguard to prevent immediate re-entry and encourages more deliberate strategy participation.

### 💸 Slashing Fund

Slashed tokens are not immediately transferred. They are deposited into an internal slashing fund.

The `receiver` (set during slashing) can later withdraw them using:

```
function withdrawSlashingFund(address token, uint256 amount) external
function withdrawETHSlashingFund(uint256 amount) external
```

These functions verify balances and authorize the caller to retrieve their accumulated slashed tokens.

&nbsp;

## :gear: _Feature activation_

[Feature activation](./specs/feature_activation.md)

## :page_facing_up: _Whitepaper_

[Whitepaper](https://ssv.network/wp-content/uploads/2025/01/SSV2.0-Based-Applications-Protocol-1.pdf)

&nbsp;

## :books: _More Resources_

[Based Apps Onboarding Guide](./doc/bAppOnBoarding.md) 

&nbsp;

## :rocket: _Deployments_

### How to Deploy

**1)** Run the deployment script defined in `scripts/`:

__`❍ npm run deploy:holesky`__: verification is done automatically.

__`❍ npm run deploy:hoodi`__: verification needs to be done manually for now.

### Public Testnet

| Name | Proxy | Implementation | Notes |
| -------- | -------- | -------- | -------- | 
| [`BasedApplications`](https://github.com/ssvlabs/based-applications/blob/main/src/BasedAppManager.sol) | [`0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A) | [`0x9a09A49870353867b0ce9901B44E84C32B2A47AC`](https://holesky.etherscan.io/address/0x9a09A49870353867b0ce9901B44E84C32B2A47AC) | Proxy: [`UUPS@5.1.0`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v5.1.0/contracts/proxy/utils/UUPSUpgradeable.sol) |

&nbsp;

## :scroll: _License_

2025 SSV Network <https://ssv.network/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the [GNU General Public License](LICENSE)
along with this program. If not, see <https://www.gnu.org/licenses/>.