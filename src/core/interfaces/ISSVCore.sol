// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IStrategyManager} from "@ssv/src/interfaces/IStrategyManager.sol";
import {IPlatformManager} from "@ssv/src/interfaces/IPlatformManager.sol";

import {SSVCoreModules} from "@ssv/src/libraries/SSVCoreStorage.sol";

interface ISSVCore {
    function initialize(address owner_, IPlatformManager ssvBasedAppManger_, IStrategyManager ssvStrategyManager_, uint32 maxFeeIncrement_) external;

    function updateModules(SSVCoreModules[] calldata moduleIds, address[] calldata moduleAddresses) external;

    function getVersion() external pure returns (string memory version);

    event ModuleUpdated(SSVCoreModules indexed moduleId, address moduleAddress);

    error TargetModuleDoesNotExist(uint8 moduleId);
    error InvalidMaxFeeIncrement();
}
