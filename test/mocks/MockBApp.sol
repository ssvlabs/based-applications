// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppCore} from "../../src/middleware-modules/BasedAppCore.sol";

contract BasedAppMock is BasedAppCore {
    event OptInToBApp(uint32 strategyId, bytes data);
    event NoEvent();

    uint32 public counter;

    constructor(address _basedAppManager, address owner) BasedAppCore(_basedAppManager, owner) {
        counter = 0;
    }

    function optInToBApp(uint32 strategyId, bytes calldata data) external override onlyManager {
        counter++;
        emit OptInToBApp(strategyId, data);
    }
}
