// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IBasedAppManager {
    event BAppMetadataURIUpdated(address indexed bAppAddress, string metadataURI);
    event BAppTokensCreated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event BAppTokensUpdated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event BAppTokensRemoved(address indexed bAppAddress, address[] tokens);
    event BAppRegistered(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevel, string metadataURI);
    event BAppTokensUpdateProposed(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event BAppTokensRemovalProposed(address indexed bAppAddress, address[] tokens);

    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function proposeBAppTokensUpdate(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function finalizeBAppTokensUpdate() external;

    function proposeBAppTokensRemoval(address[] calldata tokens) external;

    function finalizeBAppTokensRemoval() external;

    function updateBAppMetadataURI(string calldata metadataURI) external;

    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;
}
