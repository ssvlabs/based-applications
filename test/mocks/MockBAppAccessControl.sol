// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {AccessControlBasedApp} from "@ssv/src/middleware/modules/core+roles/AccessControlBasedApp.sol";

contract BasedAppMock3 is AccessControlBasedApp {
    event OptInToBApp(uint32 indexed strategyId, address[] tokens, uint32[] obligationPercentages, bytes data);

    uint32 public counter;

    constructor(address _basedAppManager, address owner) AccessControlBasedApp(_basedAppManager, owner) {
        counter = 0;
    }

    function slash(uint32, /*strategyId*/ address, /*token*/ uint256, /*amount*/ bytes calldata)
        external
        view
        override
        onlySSVBasedAppManager
        returns (bool, address, bool)
    {
        ///@dev return false on purpose to revert
        return (true, address(0), false);
    }
}
