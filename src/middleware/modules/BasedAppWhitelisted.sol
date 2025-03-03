// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedAppWhitelisted} from "@ssv/src/interfaces/IBasedAppWhitelisted.sol";

abstract contract BasedAppWhitelisted is IBasedAppWhitelisted {
    mapping(address => bool) public isWhitelisted;

    function addWhitelisted(address account) external virtual {
        if (isWhitelisted[account]) revert IBasedAppWhitelisted.AlreadyWhitelisted();
        if (account == address(0)) revert IBasedAppWhitelisted.ZeroAddress();
        isWhitelisted[account] = true;
    }

    function removeWhitelisted(address account) external virtual {
        if (!isWhitelisted[account]) revert IBasedAppWhitelisted.NotWhitelisted();
        delete isWhitelisted[account];
    }
}
