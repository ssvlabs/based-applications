// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedAppSlasher} from "@ssv/src/interfaces/IBasedAppSlasher.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";
import {BasedAppCore} from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

abstract contract BasedAppSlasher is BasedAppCore, IBasedAppSlasher {
    address public immutable SLASHER;
    uint32 public requestCounter;

    constructor(address _basedAppManager, address _initOwner) BasedAppCore(_basedAppManager) {}

    modifier onlySlasher() {
        require(msg.sender == SLASHER, "OnlySlasher");
        _;
    }

    function slash(uint32 requestId, uint32[] calldata strategies) external virtual onlySlasher {
        IBasedAppManager(BASED_APP_MANAGER).slash(strategies);
    }
}
