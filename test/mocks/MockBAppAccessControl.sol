// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {AccessControlBasedApp} from "@ssv/src/middleware/modules/core+roles/AccessControlBasedApp.sol";

contract BasedAppMock3 is AccessControlBasedApp {
    event OptInToBApp(uint32 indexed strategyId, address[] tokens, uint32[] obligationPercentages, bytes data);

    uint32 public counter;

    constructor(address _basedAppManager, address owner) AccessControlBasedApp(_basedAppManager, owner) {
        counter = 0;
    }
}
