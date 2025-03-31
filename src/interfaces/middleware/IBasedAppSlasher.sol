// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface IBasedAppSlasher {
    function slash(uint32 requestId, uint32[] calldata strategies) external;
}
