// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { IBasedAppWhitelisted } from "@ssv/src/middleware/interfaces/IBasedAppWhitelisted.sol";

abstract contract BasedAppWhitelisted is IBasedAppWhitelisted {
    mapping(uint32 => bool) public isWhitelisted;

    function addWhitelisted(uint32 strategyId) external virtual {
        if (isWhitelisted[strategyId]) {
            revert IBasedAppWhitelisted.AlreadyWhitelisted();
        }
        if (strategyId == 0) revert IBasedAppWhitelisted.ZeroID();
        isWhitelisted[strategyId] = true;
    }

    function removeWhitelisted(uint32 strategyId) external virtual {
        if (!isWhitelisted[strategyId]) {
            revert IBasedAppWhitelisted.NotWhitelisted();
        }
        delete isWhitelisted[strategyId];
    }
}
