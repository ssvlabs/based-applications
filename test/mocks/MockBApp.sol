// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {OwnableUpgradeableBasedApp} from "@ssv/src/middleware/modules/roles/OwnableUpgradeableBasedApp.sol";

contract BasedAppMock is OwnableUpgradeableBasedApp {
    event OptInToBApp(uint32 indexed strategyId, address[] tokens, uint32[] obligationPercentages, bytes data);

    uint32 public counter;

    constructor(address _basedAppManager, address owner) OwnableUpgradeableBasedApp(_basedAppManager, owner) {
        counter = 0;
    }

    function optInToBApp(
        uint32 strategyId,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external override onlySSVBasedAppManager returns (bool success) {
        counter++;
        emit OptInToBApp(strategyId, tokens, obligationPercentages, data);
        if (counter % 2 == 0) return false;
        else return true;
    }
}
