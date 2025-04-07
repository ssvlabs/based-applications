// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {BasedAppCore} from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

contract BasedAppMock2 is BasedAppCore {
    event OptInToBApp(uint32 indexed strategyId, address[] tokens, uint32[] obligationPercentages, bytes data);

    uint32 public counter;

    constructor(address _basedAppManager) BasedAppCore(_basedAppManager) {
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
        return (false, address(0), true);
    }
}
