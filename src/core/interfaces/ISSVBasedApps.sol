// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { IStrategyManager } from "@ssv/src/core/interfaces/IStrategyManager.sol";
import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { IProtocolManager } from "@ssv/src/core/interfaces/IProtocolManager.sol";
import { IViews } from "@ssv/src/core/interfaces/IViews.sol";
import { SSVCoreModules } from "@ssv/src/core/libraries/CoreStorageLib.sol";
import { ProtocolStorageLib } from "@ssv/src/core/libraries/ProtocolStorageLib.sol";
import { IStrategyFactory } from "@ssv/src/core/interfaces/IStrategyFactory.sol";

interface ISSVBasedApps is
    IStrategyManager,
    IBasedAppManager,
    IProtocolManager,
    IViews
{
    event ModuleUpdated(SSVCoreModules indexed moduleId, address moduleAddress);

    function getModuleAddress(
        SSVCoreModules moduleId
    ) external view returns (address);
    function initialize(
        address owner_,
        IBasedAppManager ssvBasedAppManger_,
        IStrategyManager ssvStrategyManager_,
        IProtocolManager protocolManager_,
        IStrategyFactory ssvStrategyFactory_,
        ProtocolStorageLib.Data memory config
    ) external;
    function updateModule(
        SSVCoreModules[] calldata moduleIds,
        address[] calldata moduleAddresses
    ) external;

    error InvalidMaxFeeIncrement();
    error InvalidMaxShares();
    error InvalidFeeTimelockPeriod();
    error InvalidFeeExpireTime();
    error InvalidWithdrawalTimelockPeriod();
    error InvalidWithdrawalExpireTime();
    error InvalidObligationTimelockPeriod();
    error InvalidObligationExpireTime();
    error InvalidTokenUpdateTimelockPeriod();
    error InvalidDisabledFeatures();
    error TargetModuleDoesNotExist(uint8 moduleId);
}
