// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IBasedAppWhitelisted {
    function addWhitelisted(address account) external;
    function removeWhitelisted(address account) external;
}
