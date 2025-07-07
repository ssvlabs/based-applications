// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.30;
import { IStrategyVault } from "@ssv/src/core/interfaces/IStrategyVault.sol";

interface IStrategyFactory {
    event NewStrategyDeployed(address owner, address strategy);
    event StrategyBeaconModified(address previousBeacon, address newBeacon);
    event SSVBasedAppsModified(
        address previousSsvBasedApps,
        address newSsvBasedApps
    );

    function createStrategy() external returns (address strategy);
}
