// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface IBasedAppManager {
    event BAppMetadataURIUpdated(
        address indexed bAppAddress,
        string metadataURI
    );
    event BAppRegistered(
        address indexed bAppAddress,
        address[] tokens,
        uint32[] sharedRiskLevel,
        string metadataURI
    );

    function registerBApp(
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external;
    function updateBAppMetadataURI(string calldata metadataURI) external;

    error BAppAlreadyRegistered();
    error BAppDoesNotSupportInterface();
    error BAppNotRegistered();
    error TokenAlreadyAddedToBApp(address token);
    error ZeroAddressNotAllowed();
}
