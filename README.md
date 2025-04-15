# :construction_worker: :closed_lock_with_key: __Based Applications Contracts__

:construction: CAUTION: This repo is currently under **heavy development!** :construction:

[![CI Tests](https://github.com/ssvlabs/based-applications/actions/workflows/tests.yml/badge.svg)](https://github.com/ssvlabs/based-applications/actions/workflows/tests.yml)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)

&nbsp;

## :book: _Description_

This repository contains the SSV Based Applications Platform Contracts.

The repository is structured in two main folders inside `src`:

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

- **`modules/core`**: the base layer for a bApp to be compliant and be recognized by the system

- **`examples`**: con

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

## :page_facing_up: _Whitepaper_

[Whitepaper](https://ssv.network/wp-content/uploads/2025/01/SSV2.0-Based-Applications-Protocol-1.pdf)

&nbsp;

## :page_facing_up: _More Resources_

[Based Apps Onboarding Guide](./doc/bapp_onboarding.md) 

&nbsp;

## :rocket: _Deployments_

### Public Testnet

| Name | Proxy | Implementation | Notes |
| -------- | -------- | -------- | -------- | 
| [`BasedApplications`](https://github.com/ssvlabs/based-applications/blob/main/src/BasedAppManager.sol) | [`0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A`](https://holesky.etherscan.io/address/0x1Bd6ceB98Daf7FfEB590236b720F81b65213836A) | [`0x9a09A49870353867b0ce9901B44E84C32B2A47AC`](https://holesky.etherscan.io/address/0x9a09A49870353867b0ce9901B44E84C32B2A47AC) | Proxy: [`UUPS@5.1.0`](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v5.1.0/contracts/proxy/utils/UUPSUpgradeable.sol) |

&nbsp;

## License

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