// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { IStrategyManager } from "@ssv/src/core/interfaces/IStrategyManager.sol";
import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { IProtocolManager } from "@ssv/src/core/interfaces/IProtocolManager.sol";
import { SSVCoreModules } from "@ssv/src/core/libraries/CoreStorageLib.sol";
import { ProtocolStorageLib } from "@ssv/src/core/libraries/ProtocolStorageLib.sol";

interface ISSVBasedApps {
    event ModuleUpdated(SSVCoreModules indexed moduleId, address moduleAddress);

    function getModuleAddress(
        SSVCoreModules moduleId
    ) external view returns (address);
    function getVersion() external pure returns (string memory version);
    function initialize(
        address owner_,
        IBasedAppManager ssvBasedAppManger_,
        IStrategyManager ssvStrategyManager_,
        IProtocolManager protocolManager_,
        ProtocolStorageLib.Data memory config
    ) external;
    function updateModule(
        SSVCoreModules[] calldata moduleIds,
        address[] calldata moduleAddresses
    ) external;

    error InvalidMaxFeeIncrement();
    error TargetModuleDoesNotExist(uint8 moduleId);
}
