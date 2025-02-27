// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IBasedApp {
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;

    function optInToBApp(
        uint32 strategyId,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external returns (bool);

    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function updateBAppTokens(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function updateBAppMetadataURI(string calldata metadataURI) external;
}
