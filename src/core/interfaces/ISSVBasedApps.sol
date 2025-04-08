// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IStrategyManager} from "@ssv/src/core/interfaces/IStrategyManager.sol";
import {IBasedAppManager} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import {ISlashingManager} from "@ssv/src/core/interfaces/ISlashingManager.sol";
import {IDelegationManager} from "@ssv/src/core/interfaces/IDelegationManager.sol";
import {ISSVDAO} from "@ssv/src/core/interfaces/ISSVDAO.sol";
import {SSVBasedAppsModules} from "@ssv/src/core/libraries/SSVBasedAppsStorage.sol";

interface ISSVBasedApps {
    function getVersion() external pure returns (string memory version);
    function initialize(
        address owner_,
        IBasedAppManager ssvBasedAppManger_,
        IStrategyManager ssvStrategyManager_,
        ISSVDAO ssvDAO_,
        ISlashingManager ssvSlashingManager_,
        IDelegationManager ssvDelegationManager_,
        uint32 maxFeeIncrement_
    ) external;
    function updateModule(SSVBasedAppsModules moduleId, address moduleAddress) external;
}
