# :construction_worker: :closed_lock_with_key: __Based Applications Contracts__

:construction: CAUTION: This repo is currently under **heavy development!** :construction:

We strongly advise you to work with **releases tags**. Please, check what version the SSVBasedApp.sol is using by calling `getVersion()`.

&nbsp;

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

## 🔨 _Slashing & Withdrawals Mechanisms_

[Slashing & Withdrawals](./guides/slashing-and-withdrawals.md)

[Generation pattern](./guides/generations.md)

## :gear: _Feature Activation_

[Feature Activation](./guides/feature-activation.md)

## :page_facing_up: _Whitepaper_

[Whitepaper](https://ssv.network/wp-content/uploads/2025/01/SSV2.0-Based-Applications-Protocol-1.pdf)


## :books: _More Resources_

[Based Apps Onboarding Guide](./guides/bApp-onboarding.md) 


## :rocket: _Deployments_

### How to Deploy

**2)** Set the environment variables in the `.env` file.

**1)** Run the deployment script `DeployAllHoodi.s.sol` defined in `script/`:

__`❍ npm run deploy:hoodi-stage`__: verification is done automatically.

### How to Update Module Contracts

It is possible to update each one of the three modules: `StrategyManager`, `BasedAppsManager` and `ProtocolManager`.

It is possible to update multiple modules at the same time. 

**1)** Go on the Proxy Contract on Etherscan, under "Write as Proxy" call the function:

__`❍ updateModules`__: specifying the correct module id and the new module address.

### How to Upgrade the Implementation Contract 

**1)** Go on the Proxy Contract on Etherscan, under "Write as Proxy" call the function:

__`❍ upgradeToAndCall`__: specifying the new implementation address. The data field can be left empty in this case.


### Public Testnet Hoodi

| Name | Proxy | Implementation | Notes |
| -------- | -------- | -------- | -------- | 
| [`SSVBasedApps`](https://github.com/ssvlabs/based-applications/blob/main/src/BasedAppManager.sol) | [`<pending>`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A) | [`<pending>`](https://holesky.etherscan.io/address/0x9a09A49870353867b0ce9901B44E84C32B2A47AC) | Proxy: [`UUPS@5.1.0`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v5.1.0/contracts/proxy/utils/UUPSUpgradeable.sol) |

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