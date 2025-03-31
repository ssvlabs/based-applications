// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IStrategyManager} from "@ssv/src/interfaces/IStrategyManager.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";
import {ISSVDAO} from "@ssv/src/interfaces/ISSVDAO.sol";

import {SSVBasedAppsModules} from "@ssv/src/libraries/SSVBasedAppsStorage.sol";

interface ISSVBasedApps {
    function initialize(address owner_, IBasedAppManager ssvBasedAppManger_, IStrategyManager ssvStrategyManager_, ISSVDAO ssvDAO_, uint32 maxFeeIncrement_)
        external;

    function getVersion() external pure returns (string memory version);

    function updateModule(SSVBasedAppsModules moduleId, address moduleAddress) external;
}
