// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.30;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {
    BeaconProxy
} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { IBeacon } from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import { ISSVBasedApps } from "@ssv/src/core/interfaces/ISSVBasedApps.sol";
import { IStrategyVault } from "@ssv/src/core/interfaces/IStrategyVault.sol";
import {
    IStrategyFactory
} from "@ssv/src/core/interfaces/IStrategyFactory.sol";

contract StrategyFactory is OwnableUpgradeable, IStrategyFactory {
    ISSVBasedApps public ssvBasedApps;
    IBeacon public strategyBeacon;

    constructor(string memory _version) {
        //todo move based aoo there
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        IBeacon _strategyBeacon,
        ISSVBasedApps _ssvBasedApps
    ) public virtual initializer {
        _transferOwnership(_initialOwner);
        _setStrategyBeacon(_strategyBeacon);
        _setSsvBasedApps(_ssvBasedApps);
    }

    function createStrategy() external returns (address strategy) {
        IStrategyVault strategyVault = IStrategyVault(
            address(
                new BeaconProxy(
                    address(strategyBeacon),
                    abi.encodeWithSelector(
                        IStrategyVault.initialize.selector,
                        address(ssvBasedApps)
                    )
                )
            )
        );
        strategy = address(strategyVault);
    }

    function _setSsvBasedApps(ISSVBasedApps _ssvBasedApps) internal {
        emit SSVBasedAppsModified(
            address(ssvBasedApps),
            address(_ssvBasedApps)
        );
        ssvBasedApps = _ssvBasedApps;
    }

    function _setStrategyBeacon(IBeacon _strategyBeacon) internal {
        emit StrategyBeaconModified(
            address(strategyBeacon),
            address(_strategyBeacon)
        );
        strategyBeacon = _strategyBeacon;
    }
}
