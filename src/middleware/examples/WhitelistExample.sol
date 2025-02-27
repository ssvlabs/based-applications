// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppWhitelisted} from "@ssv/src/middleware/modules/BasedAppWhitelisted.sol";

import {OwnableUpgradeableBasedApp} from "@ssv/src/middleware/modules/roles/OwnableUpgradeableBasedApp.sol";

contract WhitelistExample is OwnableUpgradeableBasedApp, BasedAppWhitelisted {
    constructor(address _basedAppManager, address owner) OwnableUpgradeableBasedApp(_basedAppManager, owner) {
        isWhitelisted[owner] = true;
    }

    function optInToBApp(
        uint32, /*strategyId*/
        address[] calldata, /*tokens*/
        uint32[] calldata, /*obligationPercentages*/
        bytes calldata /*data*/
    ) external view override onlySSVBasedAppManager returns (bool success) {
        if (!isWhitelisted[msg.sender]) revert NonWhitelistedCaller();
        return true;
    }
}
