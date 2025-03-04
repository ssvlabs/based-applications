// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IBasedAppWhitelisted {
    function addWhitelisted(uint32 strategyId) external;
    function removeWhitelisted(uint32 strategyId) external;

    error AlreadyWhitelisted();
    error ZeroID();
    error NotWhitelisted();
    error NonWhitelistedCaller();
}
