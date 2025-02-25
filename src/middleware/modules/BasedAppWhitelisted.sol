// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

abstract contract BasedAppWhitelisted {
    mapping(address => bool) public isWhitelisted;

    error AlreadyWhitelisted();
    error ZeroAddress();
    error NotWhitelisted();
    error NonWhitelistedCaller();

    function addWhitelisted(address account) external virtual {
        if (isWhitelisted[account]) revert AlreadyWhitelisted();
        if (account == address(0)) revert ZeroAddress();
        isWhitelisted[account] = true;
    }

    function removeWhitelisted(address account) external virtual {
        if (!isWhitelisted[account]) revert NotWhitelisted();
        delete isWhitelisted[account];
    }
}
