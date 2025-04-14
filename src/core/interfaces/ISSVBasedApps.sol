// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IStrategyManager} from "@ssv/src/core/interfaces/IStrategyManager.sol";
import {IBasedAppManager} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import {ISlashingManager} from "@ssv/src/core/interfaces/ISlashingManager.sol";
import {IDelegationManager} from "@ssv/src/core/interfaces/IDelegationManager.sol";
import {IProtocolManager} from "@ssv/src/core/interfaces/IProtocolManager.sol";
import {SSVCoreModules} from "@ssv/src/core/libraries/CoreStorageLib.sol";
import {StorageProtocol} from "@ssv/src/core/libraries/SSVBasedAppsStorageProtocol.sol";

interface ISSVBasedApps {
    function getVersion() external pure returns (string memory version);
    function initialize(
        address owner_,
        IBasedAppManager ssvBasedAppManger_,
        IStrategyManager ssvStrategyManager_,
        IProtocolManager protocolManager_,
        StorageProtocol memory config
    ) external;
    function updateModule(SSVCoreModules moduleId, address moduleAddress) external;
}
