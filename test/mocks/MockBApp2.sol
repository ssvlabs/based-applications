// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppCore} from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

contract BasedAppMock2 is BasedAppCore {
    event OptInToBApp(uint32 indexed strategyId, address[] tokens, uint32[] obligationPercentages, bytes data);

    uint32 public counter;

    constructor(address _basedAppManager) BasedAppCore(_basedAppManager) {
        counter = 0;
    }
}
