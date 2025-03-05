// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppWhitelisted} from "@ssv/src/middleware/modules/BasedAppWhitelisted.sol";

import {OwnableBasedApp} from "@ssv/src/middleware/modules/core+roles/OwnableBasedApp.sol";

contract WhitelistExample is OwnableBasedApp, BasedAppWhitelisted {
    constructor(address _basedAppManager, address owner) OwnableBasedApp(_basedAppManager, owner) {}

    function optInToBApp(
        uint32 strategyId,
        address[] calldata, /*tokens*/
        uint32[] calldata, /*obligationPercentages*/
        bytes calldata /*data*/
    ) external view override onlySSVBasedAppManager returns (bool success) {
        if (!isWhitelisted[strategyId]) revert NonWhitelistedCaller();
        return true;
    }
}
