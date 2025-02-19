// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IBasedApp {
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;

    function optInToBApp(uint32 strategyId, bytes calldata data) external returns (bool);
}
