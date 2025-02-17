// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IBasedApp {
    function updateBAppMetadataURI(string calldata metadataURI) external;

    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function updateBAppTokens(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;
}
